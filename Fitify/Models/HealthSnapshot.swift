//
//  HealthSnapshot.swift
//  Fitify
//

import Foundation

// MARK: - HRV Trend

enum HRVTrend: String, Codable {
    case improving
    case stable
    case declining
    case insufficient

    var emoji: String {
        switch self {
        case .improving: return "📈"
        case .stable: return "➡️"
        case .declining: return "📉"
        case .insufficient: return "❓"
        }
    }

    var message: String {
        switch self {
        case .improving: return "HRV покращується"
        case .stable: return "HRV стабільний"
        case .declining: return "HRV знижується"
        case .insufficient: return "Недостатньо даних"
        }
    }
}

// MARK: - Readiness Category

enum ReadinessCategory: String, Codable {
    case excellent
    case good
    case moderate
    case poor

    var emoji: String {
        switch self {
        case .excellent: return "🟢"
        case .good: return "🟡"
        case .moderate: return "🟠"
        case .poor: return "🔴"
        }
    }

    var message: String {
        switch self {
        case .excellent: return "Відмінна готовність — важке тренування"
        case .good: return "Хороша готовність — тренуйся за планом"
        case .moderate: return "Помірна готовність — легке тренування"
        case .poor: return "Низька готовність — відпочинок або йога"
        }
    }

    var intensity: String {
        switch self {
        case .excellent: return "heavy"
        case .good: return "moderate"
        case .moderate: return "light"
        case .poor: return "rest"
        }
    }
}

// MARK: - Health Snapshot

struct HealthSnapshot: Identifiable, Codable {
    let id: UUID
    let timestamp: Date

    // Vital Signs
    var heartRate: Double?
    var heartRateVariability: Double?
    var restingHeartRate: Double?
    var bodyTemperature: Double?
    var oxygenSaturation: Double?

    // Activity
    var stepCount: Int?
    var activeEnergyBurned: Double?
    var standHours: Int?

    // Sleep
    var sleepDuration: TimeInterval?
    var sleepQuality: Double?
    var deepSleepMinutes: Int?
    var remSleepMinutes: Int?

    // Extended Health Data
    var weeklyHRV: [Double]?
    var restingHRTrend: [Double]?
    var respiratoryRate: Double?
    var vo2Max: Double?
    var wristTemperature: Double?

    // Calculated Scores
    var stressLevel: Double?
    var virusRisk: RiskLevel?

    // MARK: - Computed Properties

    var sleepHours: Double {
        (sleepDuration ?? 0) / 3600.0
    }

    var hrvTrend: HRVTrend {
        guard let hrv = weeklyHRV, hrv.count >= 3 else { return .insufficient }
        let recentCount = min(3, hrv.count)
        let baselineCount = min(4, hrv.count - recentCount)
        guard baselineCount > 0 else { return .insufficient }

        let recent = hrv.suffix(recentCount).reduce(0, +) / Double(recentCount)
        let baseline = hrv.prefix(baselineCount).reduce(0, +) / Double(baselineCount)

        if recent > baseline * 1.05 { return .improving }
        if recent < baseline * 0.9 { return .declining }
        return .stable
    }

    var calculatedRecoveryScore: Int {
        var score = 50

        // HRV impact
        if let hrv = weeklyHRV?.last ?? heartRateVariability {
            if hrv > 50 { score += 20 }
            else if hrv > 30 { score += 10 }
            else { score -= 10 }
        }

        // Sleep impact
        if sleepHours > 7 { score += 20 }
        else if sleepHours > 6 { score += 10 }
        else if sleepHours < 6 { score -= 20 }

        // Resting HR impact
        if let hr = restingHeartRate {
            if hr < 60 { score += 10 }
            else if hr > 75 { score -= 10 }
        }

        // Deep sleep bonus
        if let deep = deepSleepMinutes, deep > 60 {
            score += 5
        }

        return max(0, min(100, score))
    }

    var recoveryScore: Int {
        calculatedRecoveryScore
    }

    var readinessCategory: ReadinessCategory {
        switch calculatedRecoveryScore {
        case 80...: return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        default: return .poor
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        heartRate: Double? = nil,
        heartRateVariability: Double? = nil,
        restingHeartRate: Double? = nil,
        bodyTemperature: Double? = nil,
        oxygenSaturation: Double? = nil,
        stepCount: Int? = nil,
        activeEnergyBurned: Double? = nil,
        standHours: Int? = nil,
        sleepDuration: TimeInterval? = nil,
        sleepQuality: Double? = nil,
        deepSleepMinutes: Int? = nil,
        remSleepMinutes: Int? = nil,
        weeklyHRV: [Double]? = nil,
        restingHRTrend: [Double]? = nil,
        respiratoryRate: Double? = nil,
        vo2Max: Double? = nil,
        wristTemperature: Double? = nil,
        stressLevel: Double? = nil,
        virusRisk: RiskLevel? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.heartRateVariability = heartRateVariability
        self.restingHeartRate = restingHeartRate
        self.bodyTemperature = bodyTemperature
        self.oxygenSaturation = oxygenSaturation
        self.stepCount = stepCount
        self.activeEnergyBurned = activeEnergyBurned
        self.standHours = standHours
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
        self.weeklyHRV = weeklyHRV
        self.restingHRTrend = restingHRTrend
        self.respiratoryRate = respiratoryRate
        self.vo2Max = vo2Max
        self.wristTemperature = wristTemperature
        self.stressLevel = stressLevel
        self.virusRisk = virusRisk
    }

    // MARK: - toDictionary for API

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": timestamp.timeIntervalSince1970,
            "recoveryScore": calculatedRecoveryScore,
            "hrvTrend": hrvTrend.rawValue,
            "readinessCategory": readinessCategory.rawValue,
            "sleepHours": sleepHours
        ]

        if let hr = heartRate { dict["heartRate"] = hr }
        if let hrv = heartRateVariability { dict["currentHRV"] = hrv }
        if let rhr = restingHeartRate { dict["restingHeartRate"] = rhr }
        if let temp = bodyTemperature { dict["bodyTemperature"] = temp }
        if let o2 = oxygenSaturation { dict["oxygenSaturation"] = o2 }
        if let steps = stepCount { dict["stepCount"] = steps }
        if let cal = activeEnergyBurned { dict["activeCalories"] = cal }
        if let stand = standHours { dict["standHours"] = stand }
        if let deep = deepSleepMinutes { dict["deepSleepMinutes"] = deep }
        if let rem = remSleepMinutes { dict["remSleepMinutes"] = rem }
        if let hrvArr = weeklyHRV { dict["weeklyHRV"] = hrvArr }
        if let trend = restingHRTrend { dict["restingHRTrend"] = trend }
        if let resp = respiratoryRate { dict["respiratoryRate"] = resp }
        if let vo2 = vo2Max { dict["vo2Max"] = vo2 }
        if let wrist = wristTemperature { dict["wristTemperature"] = wrist }
        if let stress = stressLevel { dict["stressLevel"] = stress }

        return dict
    }

    // MARK: - Mock Data

    static var mock: HealthSnapshot {
        HealthSnapshot(
            heartRate: 72,
            heartRateVariability: 45,
            restingHeartRate: 58,
            bodyTemperature: 36.6,
            oxygenSaturation: 98,
            stepCount: 8542,
            activeEnergyBurned: 420,
            standHours: 10,
            sleepDuration: 7.5 * 3600,
            sleepQuality: 82,
            deepSleepMinutes: 75,
            remSleepMinutes: 90,
            weeklyHRV: [42, 45, 43, 48, 50, 52, 55],
            restingHRTrend: [60, 59, 58, 58, 57, 58, 58],
            respiratoryRate: 14,
            vo2Max: 42,
            stressLevel: 35,
            virusRisk: .low
        )
    }

    static var mockMediumRisk: HealthSnapshot {
        HealthSnapshot(
            heartRate: 78,
            heartRateVariability: 32,
            restingHeartRate: 65,
            bodyTemperature: 37.2,
            oxygenSaturation: 96,
            stepCount: 4200,
            activeEnergyBurned: 180,
            standHours: 6,
            sleepDuration: 5.5 * 3600,
            sleepQuality: 58,
            deepSleepMinutes: 40,
            remSleepMinutes: 50,
            weeklyHRV: [38, 35, 33, 30, 28, 32],
            restingHRTrend: [62, 64, 65, 67, 68, 65],
            respiratoryRate: 16,
            stressLevel: 62,
            virusRisk: .medium
        )
    }
}

// MARK: - Health Trends (for weekly report)

struct HealthTrends: Codable {
    let avgHRV: Double
    let hrvTrend: String
    let avgRestingHR: Double
    let avgSleep: Double
    let avgSteps: Int
    let lowestRecoveryDay: String

    func toDictionary() -> [String: Any] {
        return [
            "avgHRV": avgHRV,
            "hrvTrend": hrvTrend,
            "avgRestingHR": avgRestingHR,
            "avgSleep": avgSleep,
            "avgSteps": avgSteps,
            "lowestRecoveryDay": lowestRecoveryDay
        ]
    }
}
