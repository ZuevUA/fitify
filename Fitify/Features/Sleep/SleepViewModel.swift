//
//  SleepViewModel.swift
//  Fitify
//

import Foundation

@Observable
final class SleepViewModel {
    private let healthKitService = HealthKitService.shared

    // Sleep data
    var totalMinutes: Int = 0
    var deepMinutes: Int = 0
    var remMinutes: Int = 0
    var lightMinutes: Int = 0
    var awakeMinutes: Int = 0
    var efficiency: Int = 0
    var bedtime: Date?
    var wakeTime: Date?

    // Timeline data (hour: phase)
    // 0=awake, 1=light, 2=rem, 3=deep
    var sleepTimeline: [(time: String, phase: Int)] = []

    // Weekly sleep hours
    var weeklySleepHours: [Double] = []
    var weekDays: [String] = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]
    var sleepGoalHours: Double = 8.0

    var isLoading = false
    var hasLoadedOnce = false
    var errorMessage: String?

    // MARK: - Computed Properties

    var formattedTotalSleep: String {
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return "\(hours)г \(mins)хв"
    }

    var formattedDeep: String {
        return "\(deepMinutes) хв"
    }

    var formattedREM: String {
        return "\(remMinutes) хв"
    }

    var formattedLight: String {
        return "\(lightMinutes) хв"
    }

    var formattedAwake: String {
        return "\(awakeMinutes) хв"
    }

    var formattedBedtime: String {
        guard let bedtime = bedtime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: bedtime)
    }

    var formattedWakeTime: String {
        guard let wakeTime = wakeTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeTime)
    }

    var sleepQualityScore: Int {
        guard totalMinutes > 0 else { return 0 }

        // Calculate based on deep sleep percentage and efficiency
        let deepPercentage = Double(deepMinutes) / Double(totalMinutes) * 100
        let remPercentage = Double(remMinutes) / Double(totalMinutes) * 100

        var score = efficiency

        // Bonus for good deep sleep (15-20% ideal)
        if deepPercentage >= 15 && deepPercentage <= 25 {
            score += 5
        }

        // Bonus for good REM (20-25% ideal)
        if remPercentage >= 18 && remPercentage <= 28 {
            score += 5
        }

        return min(100, score)
    }

    var qualityColor: String {
        switch sleepQualityScore {
        case 80...100: return "green"
        case 60..<80: return "yellow"
        default: return "red"
        }
    }

    var weeklyAverage: Double {
        guard !weeklySleepHours.isEmpty else { return 0 }
        return weeklySleepHours.reduce(0, +) / Double(weeklySleepHours.count)
    }

    var formattedWeeklyAverage: String {
        let hours = Int(weeklyAverage)
        let mins = Int((weeklyAverage - Double(hours)) * 60)
        return "\(hours)г \(mins)хв"
    }

    var aiRecommendation: String {
        if sleepQualityScore >= 80 {
            return "Твій сон цієї ночі був відмінним! Тривалість глибокого сну оптимальна для повного відновлення організму. Продовжуй дотримуватись такого режиму."
        } else if sleepQualityScore >= 60 {
            return "Сон був непоганим, але є простір для покращення. Спробуй лягати раніше та уникати екранів за годину до сну."
        } else {
            return "Якість сну нижче оптимальної. Рекомендую переглянути вечірній режим: уникай кофеїну після 14:00 та створи темне, прохолодне середовище для сну."
        }
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

            // Fetch sleep data and weekly data in parallel
            async let sleepAnalysis = healthKitService.fetchSleepAnalysis()
            async let weeklyRecovery = healthKitService.fetchWeeklyRecoveryData()

            let sleepData = try await sleepAnalysis
            let weeklyData = try await weeklyRecovery

            // Update sleep metrics
            totalMinutes = sleepData.totalMinutes
            deepMinutes = sleepData.deepMinutes
            remMinutes = sleepData.remMinutes
            lightMinutes = sleepData.lightMinutes
            awakeMinutes = sleepData.awakeMinutes
            efficiency = sleepData.efficiency
            bedtime = sleepData.bedtime
            wakeTime = sleepData.wakeTime

            // Generate timeline from bedtime to wake time
            generateSleepTimeline()

            // Update weekly sleep hours
            weeklySleepHours = weeklyData.map { $0.sleepHours ?? 0 }

        } catch {
            errorMessage = error.localizedDescription
            useMockData()
        }

        hasLoadedOnce = true
    }

    func refresh() async {
        hasLoadedOnce = false
        await loadData()
    }

    private func generateSleepTimeline() {
        guard let bedtime = bedtime, let wakeTime = wakeTime else {
            sleepTimeline = []
            return
        }

        var timeline: [(time: String, phase: Int)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        // Calculate total sleep duration
        let totalDuration = wakeTime.timeIntervalSince(bedtime)
        let segments = Int(totalDuration / 1800) // 30-minute segments

        // Generate realistic sleep phases based on actual data proportions
        let deepRatio = Double(deepMinutes) / Double(max(totalMinutes, 1))
        let remRatio = Double(remMinutes) / Double(max(totalMinutes, 1))
        let awakeRatio = Double(awakeMinutes) / Double(max(totalMinutes + awakeMinutes, 1))

        for i in 0...segments {
            let segmentTime = bedtime.addingTimeInterval(Double(i) * 1800)
            let timeString = formatter.string(from: segmentTime)

            // Determine phase based on typical sleep cycles
            let progress = Double(i) / Double(max(segments, 1))
            var phase: Int

            // Simple heuristic for sleep phases:
            // - Deep sleep is more common in first half of night
            // - REM is more common in second half
            // - Light sleep is scattered throughout
            let rand = Double.random(in: 0...1)

            if rand < awakeRatio {
                phase = 0 // Awake
            } else if progress < 0.5 && rand < awakeRatio + deepRatio * 1.5 {
                phase = 3 // Deep
            } else if progress >= 0.5 && rand < awakeRatio + remRatio * 1.5 {
                phase = 2 // REM
            } else {
                phase = 1 // Light
            }

            timeline.append((time: timeString, phase: phase))
        }

        sleepTimeline = timeline
    }

    func useMockData() {
        totalMinutes = 432
        deepMinutes = 89
        remMinutes = 95
        lightMinutes = 210
        awakeMinutes = 38
        efficiency = 84

        // Set bedtime and wake time
        let calendar = Calendar.current
        bedtime = calendar.date(bySettingHour: 23, minute: 15, second: 0, of: Date().addingTimeInterval(-86400))
        wakeTime = calendar.date(bySettingHour: 7, minute: 27, second: 0, of: Date())

        // Mock timeline
        sleepTimeline = [
            ("23:00", 1), ("23:30", 3), ("00:00", 3), ("00:30", 2),
            ("01:00", 1), ("01:30", 1), ("02:00", 3), ("02:30", 3),
            ("03:00", 2), ("03:30", 2), ("04:00", 1), ("04:30", 0),
            ("05:00", 1), ("05:30", 3), ("06:00", 2), ("06:30", 1),
            ("07:00", 0)
        ]

        // Mock weekly data
        weeklySleepHours = [6.5, 7.2, 8.1, 7.8, 6.9, 7.5, 7.2]
    }
}
