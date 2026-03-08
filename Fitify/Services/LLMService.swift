//
//  LLMService.swift
//  Fitify
//

import Foundation

@Observable
final class LLMService {
    static let shared = LLMService()

    private let session: URLSession
    private let baseURL: URL

    private(set) var isProcessing = false
    private(set) var lastError: Error?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        // Default to localhost for development
        // In production, this would be your deployed server URL
        let urlString = ProcessInfo.processInfo.environment["FITIFY_API_URL"] ?? "http://localhost:3000"
        self.baseURL = URL(string: urlString)!
    }

    // MARK: - Generate Health Insight

    func generateInsight(from snapshot: HealthSnapshot) async throws -> AIInsight {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/analyze")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let healthData = buildHealthData(from: snapshot)
        let body: [String: Any] = ["healthData": healthData]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        return try parseInsightResponse(data: data)
    }

    // MARK: - Virus/Illness Risk Check

    func checkVirusRisk(from snapshot: HealthSnapshot) async throws -> VirusRiskResult {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/virus-check")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let healthData = buildHealthData(from: snapshot)
        let body: [String: Any] = ["healthData": healthData]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        return try parseVirusCheckResponse(data: data)
    }

    // MARK: - Generate Workout Program

    func generateWorkoutProgram(from profile: UserProfile) async throws -> WorkoutProgram {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/generate-program")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // Longer timeout for program generation

        let profileData = buildProfileData(from: profile)
        let body: [String: Any] = ["userProfile": profileData]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        return try parseProgramResponse(data: data)
    }

    // MARK: - Get Workout Recommendation

    func getWorkoutRecommendation(
        workoutLog: WorkoutLog,
        previousWorkout: WorkoutLog?,
        profile: UserProfile?
    ) async throws -> WorkoutRecommendation {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/workout-recommendation")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "workoutLog": buildWorkoutLogData(from: workoutLog)
        ]

        if let previousWorkout = previousWorkout {
            body["previousWorkout"] = buildWorkoutLogData(from: previousWorkout)
        }

        if let profile = profile {
            body["userProfile"] = buildProfileData(from: profile)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        return try parseRecommendationResponse(data: data)
    }

    // MARK: - Build Profile Data

    private func buildProfileData(from profile: UserProfile) -> [String: Any] {
        let data: [String: Any] = [
            "goal": profile.goal,
            "experience": profile.experience,
            "gender": profile.gender,
            "age": profile.age,
            "weightKg": profile.weightKg,
            "trainingDaysPerWeek": profile.trainingDaysPerWeek,
            "sessionDurationMinutes": profile.sessionDurationMinutes,
            "priorityMuscles": profile.priorityMuscles,
            "calculatedWeeklyVolume": profile.calculatedWeeklyVolume,
            "sleepHours": profile.sleepHours
        ]
        print("📤 Sending to API: \(data)")
        return data
    }

    private func buildWorkoutLogData(from log: WorkoutLog) -> [String: Any] {
        let setsData = log.completedSets.map { set -> [String: Any] in
            return [
                "exerciseName": set.exerciseName,
                "weightKg": set.weightKg,
                "reps": set.reps,
                "rir": set.rir
            ]
        }

        return [
            "workoutDayName": log.workoutDayName,
            "durationMinutes": log.durationMinutes,
            "totalVolume": log.totalVolume,
            "completedSets": setsData
        ]
    }

    // MARK: - Build Health Data

    private func buildHealthData(from snapshot: HealthSnapshot) -> [String: Any] {
        var data: [String: Any] = [:]

        if let restingHR = snapshot.restingHeartRate {
            data["restingHeartRate"] = Int(restingHR)
        }
        if let hrv = snapshot.heartRateVariability {
            data["hrv"] = Int(hrv)
        }
        if let sleep = snapshot.sleepDuration {
            data["sleepHours"] = sleep / 3600.0
        }
        if let steps = snapshot.stepCount {
            data["steps"] = steps
        }
        if let calories = snapshot.activeEnergyBurned {
            data["activeCalories"] = Int(calories)
        }
        if let stress = snapshot.stressLevel {
            data["stressLevel"] = Int(stress)
        }
        data["recoveryScore"] = snapshot.recoveryScore
        if let temp = snapshot.bodyTemperature {
            data["bodyTemperature"] = temp
        }
        if let o2 = snapshot.oxygenSaturation {
            data["oxygenSaturation"] = Int(o2)
        }
        if let sleepQuality = snapshot.sleepQuality {
            data["sleepQuality"] = Int(sleepQuality)
        }

        return data
    }

    // MARK: - Parse Responses

    private func parseInsightResponse(data: Data) throws -> AIInsight {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let insight = json["insight"] as? [String: Any],
              let title = insight["title"] as? String,
              let content = insight["content"] as? String else {
            throw LLMError.parsingFailed
        }

        let categoryString = insight["category"] as? String ?? "general"
        let category = InsightCategory(rawValue: categoryString) ?? .general
        let priority = insight["priority"] as? Int ?? 3

        return AIInsight(
            title: title,
            content: content,
            category: category,
            priority: priority
        )
    }

    private func parseVirusCheckResponse(data: Data) throws -> VirusRiskResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let riskLevelString = json["riskLevel"] as? String else {
            throw LLMError.parsingFailed
        }

        let riskLevel: RiskLevel
        switch riskLevelString {
        case "high": riskLevel = .high
        case "medium": riskLevel = .medium
        default: riskLevel = .low
        }

        let confidence = json["confidence"] as? Double ?? 0.5
        let recommendation = json["recommendation"] as? String ?? ""
        let factors = json["factors"] as? [String] ?? []

        return VirusRiskResult(
            riskLevel: riskLevel,
            confidence: confidence,
            recommendation: recommendation,
            factors: factors
        )
    }

    private func parseProgramResponse(data: Data) throws -> WorkoutProgram {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let programJson = json["program"] as? [String: Any] else {
            throw LLMError.parsingFailed
        }

        let programName = programJson["programName"] as? String ?? "Моя програма"
        let splitType = programJson["splitType"] as? String ?? "PPL"
        let weeklyVolumeSummary = programJson["weeklyVolumeSummary"] as? String ?? ""
        let progressionStrategy = programJson["progressionStrategy"] as? String ?? ""
        let deloadProtocol = programJson["deloadProtocol"] as? String ?? ""
        let aiNotes = programJson["aiNotes"] as? String ?? ""
        let weeklySchedule = programJson["weeklySchedule"] as? [String] ?? []

        var workoutDays: [WorkoutDay] = []

        if let daysJson = programJson["workoutDays"] as? [[String: Any]] {
            for (dayIndex, dayJson) in daysJson.enumerated() {
                let dayName = dayJson["dayName"] as? String ?? "День \(dayIndex + 1)"
                let focus = dayJson["focus"] as? String ?? ""
                let estimatedDuration = dayJson["estimatedDurationMinutes"] as? Int ?? 60

                var exercises: [Exercise] = []

                if let exercisesJson = dayJson["exercises"] as? [[String: Any]] {
                    for (exIndex, exJson) in exercisesJson.enumerated() {
                        let exercise = Exercise(
                            name: exJson["name"] as? String ?? "",
                            nameEn: exJson["nameEn"] as? String ?? "",
                            sets: exJson["sets"] as? Int ?? 3,
                            repsMin: exJson["repsMin"] as? Int ?? 8,
                            repsMax: exJson["repsMax"] as? Int ?? 12,
                            rir: exJson["rir"] as? Int ?? 2,
                            restSeconds: exJson["restSeconds"] as? Int ?? 120,
                            notes: exJson["notes"] as? String ?? "",
                            progressionNote: exJson["progressionNote"] as? String ?? "",
                            muscleGroup: exJson["muscleGroup"] as? String ?? "",
                            exerciseType: exJson["exerciseType"] as? String ?? "compound",
                            orderIndex: exIndex
                        )
                        exercises.append(exercise)
                    }
                }

                let day = WorkoutDay(
                    dayName: dayName,
                    focus: focus,
                    estimatedDurationMinutes: estimatedDuration,
                    orderIndex: dayIndex,
                    exercises: exercises
                )
                workoutDays.append(day)
            }
        }

        let program = WorkoutProgram(
            name: programName,
            splitType: splitType,
            weeklyVolumeSummary: weeklyVolumeSummary,
            progressionStrategy: progressionStrategy,
            deloadProtocol: deloadProtocol,
            aiNotes: aiNotes,
            weeklySchedule: weeklySchedule,
            workoutDays: workoutDays,
            isActive: true  // Explicitly set active
        )
        print("📦 Created WorkoutProgram: \(program.name), isActive: \(program.isActive), days: \(program.workoutDays.count)")
        return program
    }

    // MARK: - Daily Readiness

    func fetchDailyReadiness(
        snapshot: HealthSnapshot,
        plannedWorkout: WorkoutDay?,
        recentWorkouts: [WorkoutLog]
    ) async -> DailyReadiness? {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/daily-readiness")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let recentData = recentWorkouts.prefix(7).map { log -> [String: Any] in
            return [
                "date": log.date.formatted(date: .abbreviated, time: .omitted),
                "dayName": log.workoutDayName,
                "duration": log.durationMinutes,
                "totalSets": log.completedSets.count
            ]
        }

        let body: [String: Any] = [
            "snapshot": snapshot.toDictionary(),
            "plannedWorkout": plannedWorkout?.dayName ?? "",
            "recentWorkouts": recentData
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            return try parseDailyReadinessResponse(data: data)
        } catch {
            lastError = error
            return nil
        }
    }

    private func parseDailyReadinessResponse(data: Data) throws -> DailyReadiness {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let readiness = json["readiness"] as? [String: Any] else {
            throw LLMError.parsingFailed
        }

        return DailyReadiness(
            shouldTrain: readiness["shouldTrain"] as? Bool ?? true,
            intensity: readiness["intensity"] as? String ?? "moderate",
            headline: readiness["headline"] as? String ?? "",
            reasoning: readiness["reasoning"] as? String ?? "",
            keyMetric: readiness["keyMetric"] as? String ?? "",
            warning: readiness["warning"] as? String
        )
    }

    // MARK: - Post-Workout Analysis

    func analyzeWorkout(
        completedSets: [CompletedSet],
        exercises: [Exercise],
        duration: Int,
        snapshot: HealthSnapshot,
        previousLog: WorkoutLog?
    ) async -> WorkoutAnalysis? {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/post-workout-analysis")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let setsData = completedSets.map { set -> [String: Any] in
            return [
                "exerciseId": set.exerciseId.uuidString,
                "exerciseName": set.exerciseName,
                "weightKg": set.weightKg,
                "reps": set.reps,
                "rir": set.rir
            ]
        }

        let exercisesData = exercises.map { ex -> [String: Any] in
            return [
                "id": ex.id.uuidString,
                "name": ex.name,
                "sets": ex.sets,
                "repsMin": ex.repsMin,
                "repsMax": ex.repsMax,
                "rir": ex.rir
            ]
        }

        var body: [String: Any] = [
            "completedSets": setsData,
            "exercises": exercisesData,
            "duration": duration,
            "snapshot": snapshot.toDictionary()
        ]

        if let prevLog = previousLog {
            body["previousLog"] = buildWorkoutLogData(from: prevLog)
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            return try parseWorkoutAnalysisResponse(data: data)
        } catch {
            lastError = error
            return nil
        }
    }

    private func parseWorkoutAnalysisResponse(data: Data) throws -> WorkoutAnalysis {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let analysis = json["analysis"] as? [String: Any] else {
            throw LLMError.parsingFailed
        }

        var exerciseAdvice: [WorkoutAnalysis.ExerciseAdvice] = []
        if let adviceArray = analysis["exerciseAdvice"] as? [[String: Any]] {
            for item in adviceArray {
                exerciseAdvice.append(WorkoutAnalysis.ExerciseAdvice(
                    exerciseName: item["exerciseName"] as? String ?? "",
                    nextWeight: item["nextWeight"] as? Double ?? 0,
                    nextWeightReason: item["nextWeightReason"] as? String ?? "",
                    volumeNote: item["volumeNote"] as? String ?? ""
                ))
            }
        }

        return WorkoutAnalysis(
            overallRating: analysis["overallRating"] as? Int ?? 7,
            summary: analysis["summary"] as? String ?? "",
            exerciseAdvice: exerciseAdvice,
            recoveryAdvice: analysis["recoveryAdvice"] as? String ?? "",
            nextSessionTip: analysis["nextSessionTip"] as? String ?? "",
            motivationalNote: analysis["motivationalNote"] as? String ?? ""
        )
    }

    // MARK: - Get Weekly Report

    func getWeeklyReport(
        workoutLogs: [WorkoutLog],
        profile: UserProfile?
    ) async throws -> WeeklyReport {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/weekly-report")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let logsData = workoutLogs.map { buildWorkoutLogData(from: $0) }

        var body: [String: Any] = [
            "workoutLogs": logsData
        ]

        if let profile = profile {
            body["userProfile"] = buildProfileData(from: profile)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        return try parseWeeklyReportResponse(data: data)
    }

    private func parseWeeklyReportResponse(data: Data) throws -> WeeklyReport {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success else {
            throw LLMError.parsingFailed
        }

        let weekSummary = json["weekSummary"] as? String ?? ""
        let nextWeekFocus = json["nextWeekFocus"] as? String ?? ""
        let deloadNeeded = json["deloadNeeded"] as? Bool ?? false
        let motivationalNote = json["motivationalNote"] as? String ?? ""
        let concerns = json["concerns"] as? [String] ?? []

        var topProgress: [WeeklyReport.ExerciseProgress] = []
        if let progressArray = json["topProgress"] as? [[String: Any]] {
            for item in progressArray {
                if let exercise = item["exercise"] as? String,
                   let insight = item["insight"] as? String {
                    topProgress.append(WeeklyReport.ExerciseProgress(exercise: exercise, insight: insight))
                }
            }
        }

        return WeeklyReport(
            weekSummary: weekSummary,
            topProgress: topProgress,
            concerns: concerns,
            nextWeekFocus: nextWeekFocus,
            deloadNeeded: deloadNeeded,
            motivationalNote: motivationalNote
        )
    }

    private func parseRecommendationResponse(data: Data) throws -> WorkoutRecommendation {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success else {
            throw LLMError.parsingFailed
        }

        let readinessAssessment = json["readinessAssessment"] as? String ?? ""
        let overallAdvice = json["overallAdvice"] as? String ?? ""
        let motivationalNote = json["motivationalNote"] as? String ?? ""

        var progressionJson = "[]"
        if let advice = json["progressionAdvice"] as? [[String: Any]] {
            if let jsonData = try? JSONSerialization.data(withJSONObject: advice),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                progressionJson = jsonString
            }
        }

        return WorkoutRecommendation(
            readinessAssessment: readinessAssessment,
            overallAdvice: overallAdvice,
            motivationalNote: motivationalNote,
            progressionAdviceJson: progressionJson
        )
    }

    // MARK: - Morning Briefing

    func fetchMorningBriefing(
        snapshot: HealthSnapshot,
        history: HealthHistory?,
        plannedWorkout: WorkoutDay?,
        recentFeedback: [SubjectiveFeedback],
        workoutHistory: [WorkoutLog] = []
    ) async throws -> MorningBriefing {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/morning-briefing")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let feedbackData = recentFeedback.prefix(5).map { feedback -> [String: Any] in
            return [
                "date": feedback.date.formatted(date: .abbreviated, time: .omitted),
                "text": feedback.text,
                "sentiment": feedback.sentiment,
                "tags": feedback.tags
            ]
        }

        let workoutHistoryData = workoutHistory.prefix(5).map { log -> [String: Any] in
            return [
                "date": log.date.formatted(date: .abbreviated, time: .omitted),
                "name": log.workoutDayName,
                "duration": log.durationMinutes,
                "volume": log.totalVolume
            ]
        }

        var body: [String: Any] = [
            "snapshot": snapshot.toDictionary(),
            "subjectiveFeedback": feedbackData,
            "workoutHistory": workoutHistoryData
        ]

        if let history = history {
            body["baseline"] = [
                "medianHRV": history.baseline.medianHRV,
                "medianRestingHR": history.baseline.medianRestingHR,
                "medianSleepHours": history.baseline.medianSleepHours,
                "medianSteps": history.baseline.medianSteps,
                "stdevHRV": history.baseline.stdevHRV
            ]
        }

        if let workout = plannedWorkout {
            body["plannedWorkout"] = workout.dayName
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let briefingJson = json["briefing"] as? [String: Any] else {
            throw LLMError.parsingFailed
        }

        return parseMorningBriefing(briefingJson)
    }

    private func parseMorningBriefing(_ json: [String: Any]) -> MorningBriefing {
        let todayPlanJson = json["todayPlan"] as? [String: Any]

        return MorningBriefing(
            greeting: json["greeting"] as? String ?? "Привіт!",
            readinessScore: json["readinessScore"] as? Int ?? 70,
            readinessEmoji: json["readinessEmoji"] as? String ?? "🟡",
            verdict: json["verdict"] as? String ?? "Тренуйся за планом",
            reasoning: json["reasoning"] as? [String] ?? [],
            todayPlan: TodayPlan(
                type: todayPlanJson?["type"] as? String ?? "moderate",
                suggestion: todayPlanJson?["suggestion"] as? String ?? "",
                alternativeIfTired: todayPlanJson?["alternativeIfTired"] as? String
            ),
            healthNote: json["healthNote"] as? String
        )
    }

    // Legacy method for backward compatibility
    func fetchMorningBriefingText(
        snapshot: HealthSnapshot,
        history: HealthHistory?,
        plannedWorkout: WorkoutDay?,
        recentFeedback: [SubjectiveFeedback]
    ) async throws -> String {
        let briefing = try await fetchMorningBriefing(
            snapshot: snapshot,
            history: history,
            plannedWorkout: plannedWorkout,
            recentFeedback: recentFeedback
        )
        return briefing.formattedText
    }

    // MARK: - Coach Chat

    func sendCoachMessage(
        userMessage: String,
        conversationHistory: [CoachMessage],
        snapshot: HealthSnapshot,
        history: HealthHistory?,
        todayPlan: TodayPlan?,
        recentFeedback: [SubjectiveFeedback]
    ) async throws -> CoachResponse {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/coach-message")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Build conversation history
        let historyData = conversationHistory.suffix(10).map { msg -> [String: Any] in
            return [
                "role": msg.role.rawValue,
                "content": msg.content
            ]
        }

        var body: [String: Any] = [
            "userMessage": userMessage,
            "conversationHistory": historyData,
            "snapshot": snapshot.toDictionary()
        ]

        if let history = history {
            body["baseline"] = [
                "medianHRV": history.baseline.medianHRV,
                "medianRestingHR": history.baseline.medianRestingHR,
                "medianSleepHours": history.baseline.medianSleepHours
            ]
        }

        if let plan = todayPlan {
            body["todayPlan"] = [
                "type": plan.type,
                "suggestion": plan.suggestion
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let responseJson = json["response"] as? [String: Any] else {
            throw LLMError.parsingFailed
        }

        return parseCoachResponse(responseJson)
    }

    private func parseCoachResponse(_ json: [String: Any]) -> CoachResponse {
        var action: CoachResponse.CoachAction?
        if let actionStr = json["action"] as? String {
            action = CoachResponse.CoachAction(rawValue: actionStr)
        }

        var updatedPlan: CoachResponse.UpdatedPlan?
        if let planJson = json["updatedPlan"] as? [String: Any] {
            updatedPlan = CoachResponse.UpdatedPlan(
                type: planJson["type"] as? String ?? "",
                reason: planJson["reason"] as? String ?? ""
            )
        }

        return CoachResponse(
            message: json["message"] as? String ?? "Вибач, щось пішло не так.",
            action: action,
            subjectiveTags: json["subjectiveTags"] as? [String] ?? [],
            sentiment: json["sentiment"] as? String ?? "neutral",
            updatedPlan: updatedPlan
        )
    }

    // Legacy method for backward compatibility
    func sendCoachMessageText(
        userMessage: String,
        conversationHistory: [CoachMessage],
        snapshot: HealthSnapshot,
        history: HealthHistory?,
        plannedWorkout: WorkoutDay?,
        recentFeedback: [SubjectiveFeedback]
    ) async throws -> String {
        let todayPlan = plannedWorkout != nil ? TodayPlan(
            type: "moderate",
            suggestion: plannedWorkout!.dayName,
            alternativeIfTired: nil
        ) : nil

        let response = try await sendCoachMessage(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            snapshot: snapshot,
            history: history,
            todayPlan: todayPlan,
            recentFeedback: recentFeedback
        )
        return response.message
    }

    // MARK: - Anomaly Detection

    func detectAnomalies(
        history: HealthHistory,
        recentWorkouts: [WorkoutLog] = []
    ) async throws -> AnomalyDetectionResult {
        isProcessing = true
        defer { isProcessing = false }

        let url = baseURL.appendingPathComponent("api/anomaly-detection")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45 // Longer timeout for complex analysis

        // Build history data
        let historyData = history.dailySnapshots.map { record -> [String: Any] in
            var data: [String: Any] = [
                "date": record.date.ISO8601Format()
            ]
            if let hrv = record.hrv { data["hrv"] = hrv }
            if let restingHR = record.restingHR { data["restingHR"] = restingHR }
            if let sleep = record.sleepHours { data["sleepHours"] = sleep }
            if let steps = record.steps { data["steps"] = steps }
            if let calories = record.activeCalories { data["activeCalories"] = calories }
            if let temp = record.wristTemperature { data["wristTemperature"] = temp }
            return data
        }

        // Build baseline data
        let baselineData: [String: Any] = [
            "medianHRV": history.baseline.medianHRV,
            "medianRestingHR": history.baseline.medianRestingHR,
            "medianSleepHours": history.baseline.medianSleepHours,
            "medianSteps": history.baseline.medianSteps,
            "stdevHRV": history.baseline.stdevHRV,
            "stdevRestingHR": history.baseline.stdevRestingHR
        ]

        // Build recent workouts data
        let workoutsData = recentWorkouts.prefix(7).map { log -> [String: Any] in
            return [
                "date": log.date.ISO8601Format(),
                "name": log.workoutDayName,
                "duration": log.durationMinutes,
                "volume": log.totalVolume,
                "setsCount": log.completedSets.count
            ]
        }

        let body: [String: Any] = [
            "history": historyData,
            "baseline": baselineData,
            "recentWorkouts": workoutsData
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let analysisJson = json["analysis"] as? [String: Any] else {
            throw LLMError.parsingFailed
        }

        return parseAnomalyResult(analysisJson)
    }

    private func parseAnomalyResult(_ json: [String: Any]) -> AnomalyDetectionResult {
        var anomalies: [HealthAnomaly] = []

        if let anomaliesArray = json["anomalies"] as? [[String: Any]] {
            for anomalyJson in anomaliesArray {
                let typeStr = anomalyJson["type"] as? String ?? "positive"
                let severityStr = anomalyJson["severity"] as? String ?? "low"

                let anomaly = HealthAnomaly(
                    type: HealthAnomaly.AnomalyType(rawValue: typeStr) ?? .positive,
                    severity: HealthAnomaly.Severity(rawValue: severityStr) ?? .low,
                    title: anomalyJson["title"] as? String ?? "",
                    description: anomalyJson["description"] as? String ?? "",
                    trend: anomalyJson["trend"] as? String ?? "",
                    recommendation: anomalyJson["recommendation"] as? String ?? "",
                    shouldSeeDoctor: anomalyJson["shouldSeeDoctor"] as? Bool ?? false,
                    doctorNote: anomalyJson["doctorNote"] as? String
                )
                anomalies.append(anomaly)
            }
        }

        return AnomalyDetectionResult(
            anomalies: anomalies,
            overallTrend: json["overallTrend"] as? String ?? "stable",
            weekScore: json["weekScore"] as? Int ?? 7,
            positiveNote: json["positiveNote"] as? String ?? ""
        )
    }
}

// MARK: - Virus Risk Result

struct VirusRiskResult {
    let riskLevel: RiskLevel
    let confidence: Double
    let recommendation: String
    let factors: [String]
}

// MARK: - Daily Readiness

struct DailyReadiness: Codable {
    let shouldTrain: Bool
    let intensity: String
    let headline: String
    let reasoning: String
    let keyMetric: String
    let warning: String?

    var intensityColor: String {
        switch intensity {
        case "heavy": return "green"
        case "moderate": return "blue"
        case "light": return "orange"
        case "rest": return "red"
        default: return "gray"
        }
    }
}

// MARK: - Workout Analysis

struct WorkoutAnalysis: Codable {
    let overallRating: Int
    let summary: String
    let exerciseAdvice: [ExerciseAdvice]
    let recoveryAdvice: String
    let nextSessionTip: String
    let motivationalNote: String

    struct ExerciseAdvice: Codable, Identifiable {
        var id: String { exerciseName }
        let exerciseName: String
        let nextWeight: Double
        let nextWeightReason: String
        let volumeNote: String
    }
}

// MARK: - Morning Briefing Models

struct MorningBriefing: Codable {
    let greeting: String
    let readinessScore: Int
    let readinessEmoji: String
    let verdict: String
    let reasoning: [String]
    let todayPlan: TodayPlan
    let healthNote: String?

    var formattedText: String {
        var text = "\(greeting)\n\n"
        text += "\(readinessEmoji) Готовність: \(readinessScore)/100\n\n"
        text += "**\(verdict)**\n\n"
        if !reasoning.isEmpty {
            text += reasoning.map { "• \($0)" }.joined(separator: "\n")
            text += "\n\n"
        }
        text += "📋 \(todayPlan.suggestion)"
        if let alternative = todayPlan.alternativeIfTired {
            text += "\n💤 Якщо втомлений: \(alternative)"
        }
        if let note = healthNote {
            text += "\n\n⚠️ \(note)"
        }
        return text
    }
}

struct TodayPlan: Codable {
    let type: String // heavy, moderate, light, rest, cardio
    let suggestion: String
    let alternativeIfTired: String?

    var intensityColor: String {
        switch type {
        case "heavy": return "green"
        case "moderate": return "blue"
        case "light": return "orange"
        case "rest": return "red"
        case "cardio": return "purple"
        default: return "gray"
        }
    }
}

// MARK: - Coach Response Models

struct CoachResponse: Codable {
    let message: String
    let action: CoachAction?
    let subjectiveTags: [String]
    let sentiment: String // positive, negative, neutral
    let updatedPlan: UpdatedPlan?

    enum CoachAction: String, Codable {
        case adjustWorkout
        case recordFeedback
        case suggestRest
    }

    struct UpdatedPlan: Codable {
        let type: String
        let reason: String
    }
}

// MARK: - Anomaly Detection Models

struct AnomalyDetectionResult: Codable {
    let anomalies: [HealthAnomaly]
    let overallTrend: String // improving, stable, declining
    let weekScore: Int // 1-10
    let positiveNote: String

    var hasHighSeverity: Bool {
        anomalies.contains { $0.severity == .high }
    }

    var hasMediumOrHighSeverity: Bool {
        anomalies.contains { $0.severity == .medium || $0.severity == .high }
    }
}

struct HealthAnomaly: Codable, Identifiable {
    var id: String { "\(type.rawValue)-\(title)" }

    let type: AnomalyType
    let severity: Severity
    let title: String
    let description: String
    let trend: String
    let recommendation: String
    let shouldSeeDoctor: Bool
    let doctorNote: String?

    enum AnomalyType: String, Codable {
        case overtrained
        case illness
        case sleepDebt = "sleep_debt"
        case cardiac
        case positive
    }

    enum Severity: String, Codable {
        case low
        case medium
        case high
    }

    var severityIcon: String {
        switch severity {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }

    var severityColor: String {
        switch severity {
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        }
    }

    var typeIcon: String {
        switch type {
        case .overtrained: return "figure.run"
        case .illness: return "pills.fill"
        case .sleepDebt: return "moon.zzz.fill"
        case .cardiac: return "heart.fill"
        case .positive: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case parsingFailed
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service"
        case .httpError(let statusCode):
            return "AI service error: HTTP \(statusCode)"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
