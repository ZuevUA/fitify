//
//  CoachViewModel.swift
//  Fitify
//

import Foundation
import SwiftData

@Observable
final class CoachViewModel {
    private let llmService = LLMService.shared
    private let healthKitService = HealthKitService.shared
    private let healthHistoryService = HealthHistoryService.shared

    private var modelContext: ModelContext?

    var messages: [CoachMessage] = []
    var inputText = ""
    var isThinking = false
    var isSendingMessage = false
    var errorMessage: String?

    // Voice input
    let voiceInput = VoiceInputService()
    var showVoiceInput = false

    // Health context
    var currentSnapshot: HealthSnapshot?
    var healthHistory: HealthHistory?
    var plannedWorkout: WorkoutDay?
    var currentTodayPlan: TodayPlan?

    // State tracking
    private var lastBriefingDate: Date?
    private var hasLoadedMessages = false

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCachedMessages()
        loadCoachState()
    }

    // MARK: - Message Loading

    private func loadCachedMessages() {
        guard let context = modelContext, !hasLoadedMessages else { return }

        let descriptor = FetchDescriptor<CachedCoachMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        do {
            let cached = try context.fetch(descriptor)
            messages = cached.map { $0.toCoachMessage() }
            hasLoadedMessages = true
        } catch {
            errorMessage = "Не вдалося завантажити повідомлення"
        }
    }

    private func loadCoachState() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<CoachState>()

        do {
            if let state = try context.fetch(descriptor).first {
                lastBriefingDate = state.lastBriefingDate
            }
        } catch {
            // Ignore errors, will trigger briefing
        }
    }

    private func saveCoachState() {
        guard let context = modelContext else { return }

        // Delete old states
        do {
            try context.delete(model: CoachState.self)
        } catch { }

        let state = CoachState(lastBriefingDate: lastBriefingDate)
        context.insert(state)
        try? context.save()
    }

    // MARK: - Morning Briefing

    var needsMorningBriefing: Bool {
        guard let lastDate = lastBriefingDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }

    func checkAndSendMorningBriefing() async {
        guard needsMorningBriefing else { return }
        guard !isThinking else { return }

        isThinking = true
        errorMessage = nil

        // Fetch current health data
        await loadHealthContext()

        do {
            let briefing = try await llmService.fetchMorningBriefing(
                snapshot: currentSnapshot ?? .mock,
                history: healthHistory,
                plannedWorkout: plannedWorkout,
                recentFeedback: fetchRecentFeedback()
            )

            // Save today plan for chat context
            currentTodayPlan = briefing.todayPlan

            let message = CoachMessage.morningBriefing(briefing)
            appendMessage(message)

            lastBriefingDate = Date()
            saveCoachState()

        } catch {
            // Use fallback greeting
            let fallbackGreeting = generateFallbackGreeting()
            appendMessage(CoachMessage.morningBriefing(fallbackGreeting))
            lastBriefingDate = Date()
            saveCoachState()
        }

        isThinking = false
    }

    private func generateFallbackGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        switch hour {
        case 5..<12:
            greeting = "Доброго ранку!"
        case 12..<18:
            greeting = "Добрий день!"
        default:
            greeting = "Добрий вечір!"
        }

        if let snapshot = currentSnapshot {
            let recovery = snapshot.recoveryScore
            if recovery >= 80 {
                return "\(greeting) Твій Recovery Score сьогодні \(recovery)% — відмінний день для інтенсивного тренування! Як себе почуваєш?"
            } else if recovery >= 60 {
                return "\(greeting) Твій Recovery Score — \(recovery)%. Помірне навантаження буде оптимальним. Розкажи, як твій настрій сьогодні?"
            } else {
                return "\(greeting) Твій Recovery Score трохи нижчий за звичайний — \(recovery)%. Можливо, варто зробити легке тренування або відпочити. Як ти себе почуваєш?"
            }
        }

        return "\(greeting) Я твій AI-тренер. Розкажи, як ти себе почуваєш сьогодні?"
    }

    // MARK: - Send Message

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isSendingMessage else { return }

        inputText = ""
        isSendingMessage = true
        isThinking = true
        errorMessage = nil

        // Add user message
        let userMessage = CoachMessage.user(text)
        appendMessage(userMessage)

        // Save subjective feedback if it contains feelings
        saveSubjectiveFeedback(text)

        // Ensure we have context
        if currentSnapshot == nil {
            await loadHealthContext()
        }

        do {
            let response = try await llmService.sendCoachMessage(
                userMessage: text,
                conversationHistory: recentConversationContext(),
                snapshot: currentSnapshot ?? .mock,
                history: healthHistory,
                todayPlan: currentTodayPlan,
                recentFeedback: fetchRecentFeedback()
            )

            let assistantMessage = CoachMessage.fromCoachResponse(response)
            appendMessage(assistantMessage)

            // Handle actions from coach response
            handleCoachAction(response)

        } catch {
            errorMessage = "Не вдалося отримати відповідь"
            // Remove user message if failed
            if messages.last?.id == userMessage.id {
                messages.removeLast()
            }
        }

        isThinking = false
        isSendingMessage = false
    }

    // MARK: - Coach Actions

    private func handleCoachAction(_ response: CoachResponse) {
        // Update today plan if coach suggests a change
        if let updatedPlan = response.updatedPlan {
            currentTodayPlan = TodayPlan(
                type: updatedPlan.type,
                suggestion: updatedPlan.reason,
                alternativeIfTired: nil
            )
        }

        // Save subjective tags as feedback if present
        if !response.subjectiveTags.isEmpty, let context = modelContext {
            let feedback = SubjectiveFeedback(
                text: response.subjectiveTags.joined(separator: ", "),
                sentiment: response.sentiment,
                tags: response.subjectiveTags
            )
            context.insert(feedback)
            try? context.save()
        }
    }

    // MARK: - Voice Input

    func handleVoiceInput() {
        if !voiceInput.transcript.isEmpty {
            inputText = voiceInput.transcript
            voiceInput.transcript = ""
        }
        showVoiceInput = false
    }

    // MARK: - Context

    private func loadHealthContext() async {
        // Load current snapshot
        if healthKitService.isHealthKitAvailable {
            do {
                let data = try await healthKitService.fetchAllDashboardData()
                currentSnapshot = HealthSnapshot(
                    heartRate: data.heartRate,
                    heartRateVariability: data.hrv,
                    restingHeartRate: data.restingHR,
                    bodyTemperature: data.bodyTemp,
                    oxygenSaturation: data.oxygenSat,
                    stepCount: data.steps,
                    activeEnergyBurned: data.calories,
                    standHours: data.standHours,
                    sleepDuration: TimeInterval(data.sleepData.totalMinutes * 60),
                    deepSleepMinutes: data.sleepData.deepMinutes,
                    remSleepMinutes: data.sleepData.remMinutes,
                    weeklyHRV: data.weeklyHRV,
                    restingHRTrend: data.restingHRTrend,
                    respiratoryRate: data.respiratoryRate,
                    vo2Max: data.vo2Max,
                    wristTemperature: data.wristTemperature
                )
            } catch {
                currentSnapshot = .mock
            }
        } else {
            currentSnapshot = .mock
        }

        // Load health history (cached)
        healthHistory = await healthHistoryService.fetchHealthHistory(forceRefresh: false)
    }

    private func recentConversationContext() -> [CoachMessage] {
        // Last 10 messages for context
        Array(messages.suffix(10))
    }

    private func fetchRecentFeedback() -> [SubjectiveFeedback] {
        guard let context = modelContext else { return [] }

        var descriptor = FetchDescriptor<SubjectiveFeedback>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 5

        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    // MARK: - Subjective Feedback

    private func saveSubjectiveFeedback(_ text: String) {
        guard let context = modelContext else { return }

        // Simple heuristic: save if message contains feeling words
        let feelingKeywords = [
            "почуваюсь", "почуваю", "відчуваю", "болить", "втома", "енергія",
            "настрій", "сон", "спав", "важко", "легко", "добре", "погано",
            "м'язи", "ноги", "спина", "голова", "стрес", "тривога"
        ]

        let lowercasedText = text.lowercased()
        let containsFeelings = feelingKeywords.contains { lowercasedText.contains($0) }

        guard containsFeelings else { return }

        // Extract tags based on keywords found
        var tags: [String] = []
        for keyword in feelingKeywords where lowercasedText.contains(keyword) {
            tags.append(keyword)
        }

        // Determine sentiment (simple heuristic)
        let positiveWords = ["добре", "чудово", "енергія", "легко", "відпочив"]
        let negativeWords = ["погано", "болить", "втома", "важко", "стрес", "тривога"]

        var sentiment = "neutral"
        if positiveWords.contains(where: { lowercasedText.contains($0) }) {
            sentiment = "positive"
        } else if negativeWords.contains(where: { lowercasedText.contains($0) }) {
            sentiment = "negative"
        }

        let feedback = SubjectiveFeedback(
            text: text,
            sentiment: sentiment,
            tags: Array(Set(tags)) // Remove duplicates
        )

        context.insert(feedback)
        try? context.save()
    }

    // MARK: - Message Management

    private func appendMessage(_ message: CoachMessage) {
        messages.append(message)
        saveMessage(message)
    }

    private func saveMessage(_ message: CoachMessage) {
        guard let context = modelContext else { return }

        let cached = CachedCoachMessage(from: message)
        context.insert(cached)
        try? context.save()
    }

    func clearHistory() {
        guard let context = modelContext else { return }

        do {
            try context.delete(model: CachedCoachMessage.self)
            try context.save()
            messages = []
        } catch {
            errorMessage = "Не вдалося очистити історію"
        }
    }

    // MARK: - Anomaly Detection

    /// Send anomaly detection result as a coach message
    func sendAnomalyReport(_ result: AnomalyDetectionResult) {
        // Only send if there are anomalies or it's a weekly summary
        guard !result.anomalies.isEmpty || result.weekScore < 7 else { return }

        // Build message content
        var content = "Тижневий аналіз здоров'я\n\n"
        content += "Оцінка тижня: \(result.weekScore)/10\n"

        let trendEmoji: String
        switch result.overallTrend {
        case "improving": trendEmoji = "📈"
        case "declining": trendEmoji = "📉"
        default: trendEmoji = "➡️"
        }
        content += "Тренд: \(trendEmoji) \(result.overallTrend == "improving" ? "Покращення" : result.overallTrend == "declining" ? "Спад" : "Стабільно")\n\n"

        if !result.positiveNote.isEmpty {
            content += "✅ \(result.positiveNote)\n\n"
        }

        // Add anomalies
        let importantAnomalies = result.anomalies.filter { $0.severity == .high || $0.severity == .medium }
        if !importantAnomalies.isEmpty {
            content += "⚠️ Важливо:\n"
            for anomaly in importantAnomalies {
                content += "\n• \(anomaly.title)\n"
                content += "  \(anomaly.description)\n"
                content += "  💡 \(anomaly.recommendation)\n"

                if anomaly.shouldSeeDoctor, let note = anomaly.doctorNote {
                    content += "  🏥 \(note)\n"
                }
            }
        }

        let message = CoachMessage(
            role: .assistant,
            content: content,
            type: .weeklyReport
        )

        appendMessage(message)
    }

    /// Check and send weekly anomaly report if it's Sunday
    func checkAndSendWeeklyReport(workoutLogs: [WorkoutLog] = []) async {
        let calendar = Calendar.current
        let isSunday = calendar.component(.weekday, from: Date()) == 1

        guard isSunday else { return }

        // Load health history if needed
        if healthHistory == nil {
            await loadHealthContext()
        }

        guard let history = healthHistory else { return }

        isThinking = true

        do {
            let result = try await llmService.detectAnomalies(
                history: history,
                recentWorkouts: workoutLogs
            )

            sendAnomalyReport(result)

        } catch {
            // Silent failure for weekly report
        }

        isThinking = false
    }
}
