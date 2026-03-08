//
//  InsightsViewModel.swift
//  Fitify
//

import Foundation

@Observable
final class InsightsViewModel {
    private let storageService = StorageService.shared
    private let llmService = LLMService.shared
    private let healthHistoryService = HealthHistoryService.shared

    var allInsights: [AIInsight] = []
    var selectedFilter: InsightFilter = .all
    var isLoading = false
    var hasLoadedOnce = false
    var isGenerating = false
    var errorMessage: String?

    // Health History
    var healthHistory: HealthHistory?
    var isSyncingHistory = false
    var historySyncProgress: Double = 0

    // Anomaly Detection
    var anomalyResult: AnomalyDetectionResult?
    var isDetectingAnomalies = false
    var lastAnomalyDetectionDate: Date?

    var filteredInsights: [AIInsight] {
        switch selectedFilter {
        case .all:
            return allInsights
        case .sleep:
            return allInsights.filter { $0.insightCategory == .sleep }
        case .activity:
            return allInsights.filter { $0.insightCategory == .activity }
        case .stress:
            return allInsights.filter { $0.insightCategory == .stress }
        case .health:
            return allInsights.filter { $0.insightCategory == .illness || $0.insightCategory == .recovery }
        }
    }

    var groupedInsights: [(date: String, insights: [AIInsight])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: filteredInsights) { insight -> String in
            if calendar.isDateInToday(insight.timestamp) {
                return "Сьогодні"
            } else if calendar.isDateInYesterday(insight.timestamp) {
                return "Вчора"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "uk_UA")
                formatter.dateFormat = "d MMMM"
                return formatter.string(from: insight.timestamp)
            }
        }

        return grouped.map { (date: $0.key, insights: $0.value) }
            .sorted { first, second in
                if first.date == "Сьогодні" { return true }
                if second.date == "Сьогодні" { return false }
                if first.date == "Вчора" { return true }
                if second.date == "Вчора" { return false }
                return first.insights.first?.timestamp ?? Date() > second.insights.first?.timestamp ?? Date()
            }
    }

    var unreadCount: Int {
        allInsights.filter { !$0.isRead }.count
    }

    func loadInsights() {
        guard !hasLoadedOnce else { return }
        allInsights = storageService.fetchInsights()
        if allInsights.isEmpty {
            useMockData()
        }
        hasLoadedOnce = true
    }

    func refresh() {
        hasLoadedOnce = false
        loadInsights()
    }

    func generateNewInsight(from snapshot: HealthSnapshot) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await llmService.generateInsight(from: snapshot)
            storageService.saveInsight(insight)
            loadInsights()
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    func markAsRead(_ insight: AIInsight) {
        storageService.markInsightAsRead(insight)
    }

    func deleteInsight(_ insight: AIInsight) {
        storageService.deleteInsight(insight)
        loadInsights()
    }

    // MARK: - Health History Sync

    /// Syncs health history if cache is stale (> 24 hours)
    func syncHistoryIfNeeded() async {
        guard !isSyncingHistory else { return }

        // Check if refresh is needed
        guard healthHistoryService.needsRefresh() else {
            // Load from cache
            healthHistory = await healthHistoryService.fetchHealthHistory(forceRefresh: false)
            return
        }

        await syncHistory()
    }

    /// Force sync health history from HealthKit
    func syncHistory() async {
        isSyncingHistory = true
        historySyncProgress = 0

        // Monitor progress
        let progressTask = Task {
            while !Task.isCancelled {
                historySyncProgress = healthHistoryService.syncProgress
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }

        healthHistory = await healthHistoryService.fetchFullHealthHistory()

        progressTask.cancel()
        historySyncProgress = 1.0
        isSyncingHistory = false
    }

    /// Check if current metric is anomalous compared to baseline
    func isAnomalous(hrv: Double) -> Bool {
        healthHistory?.isHRVAnomalous(hrv) ?? false
    }

    func isAnomalous(restingHR: Double) -> Bool {
        healthHistory?.isRestingHRAnomalous(restingHR) ?? false
    }

    /// Get baseline values
    var baseline: UserBaseline? {
        healthHistory?.baseline
    }

    /// Get trend for HRV
    var hrvTrend: TrendDirection {
        healthHistory?.trend(for: \.hrv) ?? .insufficient
    }

    /// Get trend for resting heart rate
    var restingHRTrend: TrendDirection {
        healthHistory?.trend(for: \.restingHR) ?? .insufficient
    }

    func useMockData() {
        allInsights = [
            AIInsight(
                timestamp: Date(),
                title: "Відмінне відновлення",
                content: "Твій HRV зріс на 12% за останній тиждень. Це свідчить про хорошу адаптацію до тренувань та якісний відпочинок. Продовжуй в тому ж дусі!",
                category: .recovery,
                priority: 1
            ),
            AIInsight(
                timestamp: Date().addingTimeInterval(-3600),
                title: "Патерн сну виявлено",
                content: "Ти лягаєш спати на 40 хвилин пізніше у вихідні. Стабільний графік сну покращить якість відновлення.",
                category: .sleep,
                priority: 2
            ),
            AIInsight(
                timestamp: Date().addingTimeInterval(-86400),
                title: "Ціль кроків досягнута!",
                content: "Ти досяг цілі 10,000 кроків 5 днів поспіль! Можеш збільшити ціль до 11,000 для подальшого прогресу.",
                category: .activity,
                priority: 3
            ),
            AIInsight(
                timestamp: Date().addingTimeInterval(-86400 * 2),
                title: "Рівень стресу знизився",
                content: "За останні 3 дні твій середній рівень стресу знизився з 58% до 34%. Техніки релаксації працюють!",
                category: .stress,
                priority: 2
            ),
            AIInsight(
                timestamp: Date().addingTimeInterval(-86400 * 3),
                title: "Підвищений пульс вночі",
                content: "Минулої ночі твій пульс був на 8 уд/хв вище норми. Можливо, варто уникати кофеїну та важкої їжі перед сном.",
                category: .illness,
                priority: 1,
                isRead: true
            )
        ]
    }

    // MARK: - Anomaly Detection

    /// Check if it's Sunday and we haven't run detection this week
    var shouldRunWeeklyAnomalyDetection: Bool {
        let calendar = Calendar.current
        let today = Date()

        // Check if it's Sunday (weekday = 1 in Gregorian calendar)
        let isSunday = calendar.component(.weekday, from: today) == 1

        // Check if we already ran detection this week
        if let lastDate = lastAnomalyDetectionDate {
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            if lastDate > weekAgo {
                return false // Already ran this week
            }
        }

        return isSunday
    }

    /// Run anomaly detection if conditions are met
    func runAnomalyDetectionIfNeeded(workoutLogs: [WorkoutLog] = []) async {
        guard shouldRunWeeklyAnomalyDetection else { return }
        guard !isDetectingAnomalies else { return }

        await runAnomalyDetection(workoutLogs: workoutLogs)
    }

    /// Force run anomaly detection
    func runAnomalyDetection(workoutLogs: [WorkoutLog] = []) async {
        guard !isDetectingAnomalies else { return }

        // Ensure we have health history
        if healthHistory == nil {
            await syncHistoryIfNeeded()
        }

        guard let history = healthHistory else {
            errorMessage = "Не вдалося завантажити історію здоров'я"
            return
        }

        isDetectingAnomalies = true
        errorMessage = nil

        do {
            let result = try await llmService.detectAnomalies(
                history: history,
                recentWorkouts: workoutLogs
            )

            anomalyResult = result
            lastAnomalyDetectionDate = Date()

            // Create insights from high severity anomalies
            createInsightsFromAnomalies(result)

        } catch {
            errorMessage = "Помилка аналізу: \(error.localizedDescription)"
        }

        isDetectingAnomalies = false
    }

    /// Create AIInsights from detected anomalies
    private func createInsightsFromAnomalies(_ result: AnomalyDetectionResult) {
        for anomaly in result.anomalies where anomaly.severity == .high || anomaly.severity == .medium {
            let category: InsightCategory
            switch anomaly.type {
            case .illness: category = .illness
            case .sleepDebt: category = .sleep
            case .cardiac: category = .illness
            case .overtrained: category = .recovery
            case .positive: category = .recovery
            }

            let priority = anomaly.severity == .high ? 1 : 2

            var content = anomaly.description + "\n\n" + anomaly.recommendation
            if anomaly.shouldSeeDoctor, let doctorNote = anomaly.doctorNote {
                content += "\n\n\(doctorNote)"
            }

            let insight = AIInsight(
                timestamp: Date(),
                title: anomaly.title,
                content: content,
                category: category,
                priority: priority
            )

            storageService.saveInsight(insight)
        }

        // Refresh insights list
        refresh()
    }

    /// Check if there are important anomalies to show
    var hasImportantAnomalies: Bool {
        anomalyResult?.hasMediumOrHighSeverity ?? false
    }

    /// Get high severity anomalies for notifications
    var highSeverityAnomalies: [HealthAnomaly] {
        anomalyResult?.anomalies.filter { $0.severity == .high } ?? []
    }
}

// MARK: - Filter

enum InsightFilter: String, CaseIterable, Identifiable {
    case all = "Всі"
    case sleep = "Сон"
    case activity = "Активність"
    case stress = "Стрес"
    case health = "Здоров'я"

    var id: String { rawValue }
}
