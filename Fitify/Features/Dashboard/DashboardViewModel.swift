//
//  DashboardViewModel.swift
//  Fitify
//

import Foundation

@Observable
final class DashboardViewModel {
    private let healthKitService = HealthKitService.shared
    private let storageService = StorageService.shared
    private let llmService = LLMService.shared

    var snapshot: HealthSnapshot = .mock
    var latestInsight: AIInsight?
    var isLoading = false
    var hasLoadedOnce = false
    var isGeneratingInsight = false
    var errorMessage: String?
    var showingPermissionAlert = false

    // Trends (difference from yesterday)
    var heartRateTrend: Int = -3
    var hrvTrend: Int = 5
    var sleepTrend: Int = 12 // minutes
    var stressTrend: Int = -8

    // Weekly recovery scores
    var weeklyRecoveryScores: [Int] = [72, 68, 81, 75, 69, 78, 82]
    var weekDays: [String] = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]

    var recoveryScore: Int {
        snapshot.recoveryScore
    }

    var stressLevel: Double {
        snapshot.stressLevel ?? HealthCalculations.calculateStressLevel(
            heartRate: snapshot.heartRate,
            hrv: snapshot.heartRateVariability,
            restingHeartRate: snapshot.restingHeartRate,
            sleepDuration: snapshot.sleepDuration
        )
    }

    var virusRisk: RiskLevel {
        snapshot.virusRisk ?? HealthCalculations.assessVirusRisk(
            bodyTemperature: snapshot.bodyTemperature,
            restingHeartRate: snapshot.restingHeartRate,
            hrv: snapshot.heartRateVariability,
            oxygenSaturation: snapshot.oxygenSaturation
        )
    }

    // MARK: - Formatted Values

    var formattedHeartRate: String {
        guard let hr = snapshot.heartRate else { return "--" }
        return "\(Int(hr))"
    }

    var formattedHRV: String {
        guard let hrv = snapshot.heartRateVariability else { return "--" }
        return "\(Int(hrv))"
    }

    var formattedSleep: String {
        guard let sleep = snapshot.sleepDuration else { return "--" }
        return HealthCalculations.formatSleepDuration(sleep)
    }

    var formattedStress: String {
        return "\(Int(stressLevel))"
    }

    // MARK: - Greeting

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Доброго ранку ☀️"
        case 12..<18:
            return "Добрий день 👋"
        default:
            return "Добрий вечір 🌙"
        }
    }

    var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date()).capitalized
    }

    var recoveryRecommendation: String {
        switch recoveryScore {
        case 80...100:
            return "Відмінний день для інтенсивного тренування 💪"
        case 50..<80:
            return "Помірне навантаження. Прислухайся до тіла 🎯"
        default:
            return "Організм відновлюється. Рекомендовано відпочинок 🛌"
        }
    }

    // MARK: - Status Indicators

    func isMetricNormal(_ metric: MetricType) -> Bool {
        switch metric {
        case .heartRate:
            guard let hr = snapshot.heartRate else { return true }
            return hr >= 60 && hr <= 100
        case .hrv:
            guard let hrv = snapshot.heartRateVariability else { return true }
            return hrv >= 30
        case .sleep:
            guard let sleep = snapshot.sleepDuration else { return true }
            return sleep >= 6 * 3600
        case .stress:
            return stressLevel < 60
        }
    }

    enum MetricType {
        case heartRate, hrv, sleep, stress
    }

    // MARK: - Actions

    func loadData() async {
        guard !isLoading else { return }
        guard !hasLoadedOnce else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard healthKitService.isHealthKitAvailable else {
                useMockData()
                hasLoadedOnce = true
                return
            }

            if !healthKitService.isAuthorized {
                try await healthKitService.requestPermissions()
            }

            // Fetch all data in parallel
            async let dashboardData = healthKitService.fetchAllDashboardData()
            async let weeklyData = healthKitService.fetchWeeklyRecoveryData()

            let data = try await dashboardData
            let weekly = try await weeklyData

            // Calculate sleep quality from sleep data
            let sleepQuality = HealthCalculations.calculateSleepQuality(
                totalSleep: TimeInterval(data.sleepData.totalMinutes * 60),
                deepSleep: TimeInterval(data.sleepData.deepMinutes * 60),
                remSleep: TimeInterval(data.sleepData.remMinutes * 60)
            )

            // Create snapshot with fetched data including extended health metrics
            var newSnapshot = HealthSnapshot(
                heartRate: data.heartRate,
                heartRateVariability: data.hrv,
                restingHeartRate: data.restingHR,
                bodyTemperature: data.bodyTemp,
                oxygenSaturation: data.oxygenSat,
                stepCount: data.steps,
                activeEnergyBurned: data.calories,
                standHours: data.standHours,
                sleepDuration: TimeInterval(data.sleepData.totalMinutes * 60),
                sleepQuality: sleepQuality,
                deepSleepMinutes: data.sleepData.deepMinutes,
                remSleepMinutes: data.sleepData.remMinutes,
                weeklyHRV: data.weeklyHRV,
                restingHRTrend: data.restingHRTrend,
                respiratoryRate: data.respiratoryRate,
                vo2Max: data.vo2Max,
                wristTemperature: data.wristTemperature
            )

            // Calculate derived scores (recoveryScore is computed automatically)
            newSnapshot.stressLevel = HealthCalculations.calculateStressLevel(
                heartRate: data.heartRate,
                hrv: data.hrv,
                restingHeartRate: data.restingHR,
                sleepDuration: TimeInterval(data.sleepData.totalMinutes * 60)
            )
            newSnapshot.virusRisk = HealthCalculations.assessVirusRisk(
                bodyTemperature: data.bodyTemp,
                restingHeartRate: data.restingHR,
                hrv: data.hrv,
                oxygenSaturation: data.oxygenSat
            )

            snapshot = newSnapshot

            // Update weekly data and trends
            updateWeeklyData(from: weekly)
            calculateTrends(from: weekly)

        } catch {
            errorMessage = error.localizedDescription
            useMockData()
        }

        latestInsight = storageService.fetchLatestInsight()
        hasLoadedOnce = true
    }

    private func updateWeeklyData(from data: [DailyHealthData]) {
        weeklyRecoveryScores = data.map { $0.recoveryScore ?? 70 }
    }

    private func calculateTrends(from data: [DailyHealthData]) {
        guard data.count >= 2 else { return }

        let today = data.last
        let yesterday = data[data.count - 2]

        // HRV trend
        if let todayHRV = today?.hrv, let yesterdayHRV = yesterday.hrv {
            hrvTrend = Int(todayHRV - yesterdayHRV)
        }

        // Heart rate trend
        if let todayRHR = today?.restingHeartRate, let yesterdayRHR = yesterday.restingHeartRate {
            heartRateTrend = Int(todayRHR - yesterdayRHR)
        }

        // Sleep trend (in minutes)
        if let todaySleep = today?.sleepHours, let yesterdaySleep = yesterday.sleepHours {
            sleepTrend = Int((todaySleep - yesterdaySleep) * 60)
        }
    }

    func refresh() async {
        hasLoadedOnce = false
        await loadData()
    }

    // MARK: - AI Integration

    func generateAIInsight() async {
        guard !isGeneratingInsight else { return }
        isGeneratingInsight = true

        do {
            let insight = try await llmService.generateInsight(from: snapshot)
            storageService.saveInsight(insight)
            latestInsight = insight
        } catch {
            // Silently fail - AI insight is optional
            print("Failed to generate AI insight: \(error.localizedDescription)")
        }

        isGeneratingInsight = false
    }

    func checkVirusRiskWithAI() async {
        do {
            let result = try await llmService.checkVirusRisk(from: snapshot)
            snapshot.virusRisk = result.riskLevel
        } catch {
            // Fall back to local calculation
            print("Failed to check virus risk with AI: \(error.localizedDescription)")
        }
    }

    func useMockData() {
        snapshot = HealthSnapshot(
            heartRate: 72,
            heartRateVariability: 48,
            restingHeartRate: 58,
            bodyTemperature: 36.6,
            oxygenSaturation: 98,
            stepCount: 7234,
            activeEnergyBurned: 487,
            sleepDuration: 7.2 * 3600,
            sleepQuality: 84,
            stressLevel: 32,
            virusRisk: .low
        )
        latestInsight = AIInsight(
            title: "Твій сон покращився",
            content: "За останній тиждень тривалість глибокого сну зросла на 15%. Продовжуй дотримуватись режиму — це позитивно впливає на відновлення організму.",
            category: .sleep,
            priority: 1
        )
    }
}
