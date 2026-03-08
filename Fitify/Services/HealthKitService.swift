//
//  HealthKitService.swift
//  Fitify
//

import Foundation
import HealthKit

// MARK: - Data Models

struct SleepData {
    let totalMinutes: Int
    let deepMinutes: Int
    let remMinutes: Int
    let lightMinutes: Int
    let awakeMinutes: Int
    let efficiency: Int
    let bedtime: Date?
    let wakeTime: Date?

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    static let empty = SleepData(
        totalMinutes: 0,
        deepMinutes: 0,
        remMinutes: 0,
        lightMinutes: 0,
        awakeMinutes: 0,
        efficiency: 0,
        bedtime: nil,
        wakeTime: nil
    )
}

struct DailyHealthData: Identifiable {
    let id = UUID()
    let date: Date
    let restingHeartRate: Double?
    let hrv: Double?
    let sleepHours: Double?
    let steps: Int?
    let calories: Double?
    let recoveryScore: Int?
}

// MARK: - Mock Data

enum HealthKitMockData {
    static let restingHeartRate: Double = 58
    static let hrv: Double = 52
    static let heartRate: Double = 72
    static let bodyTemperature: Double = 36.6
    static let oxygenSaturation: Double = 98
    static let steps: Int = 7234
    static let calories: Double = 487

    static let sleepData = SleepData(
        totalMinutes: 432,
        deepMinutes: 89,
        remMinutes: 95,
        lightMinutes: 210,
        awakeMinutes: 38,
        efficiency: 84,
        bedtime: Calendar.current.date(bySettingHour: 23, minute: 15, second: 0, of: Date().addingTimeInterval(-86400)),
        wakeTime: Calendar.current.date(bySettingHour: 7, minute: 27, second: 0, of: Date())
    )

    static let weeklyData: [DailyHealthData] = {
        let calendar = Calendar.current
        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return DailyHealthData(
                date: date,
                restingHeartRate: Double.random(in: 55...65),
                hrv: Double.random(in: 40...60),
                sleepHours: Double.random(in: 6.0...8.5),
                steps: Int.random(in: 5000...12000),
                calories: Double.random(in: 300...600),
                recoveryScore: Int.random(in: 60...90)
            )
        }.reversed()
    }()
}

// MARK: - HealthKit Service

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false
    private(set) var authorizationError: Error?

    private init() {}

    // MARK: - Authorization

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []

        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .bodyTemperature,
            .oxygenSaturation,
            .stepCount,
            .activeEnergyBurned,
            .respiratoryRate,
            .vo2Max,
            .appleSleepingWristTemperature
        ]

        for identifier in quantityIdentifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        if let standType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) {
            types.insert(standType)
        }

        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []

        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned
        ]

        for identifier in quantityIdentifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        return types
    }

    func requestPermissions() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    func checkAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }

    // MARK: - Resting Heart Rate

    func fetchRestingHeartRate() async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return HealthKitMockData.restingHeartRate
        }

        let value = try await fetchLatestQuantity(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
        return value ?? HealthKitMockData.restingHeartRate
    }

    // MARK: - HRV (average over last 24 hours)

    func fetchHRV() async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return HealthKitMockData.hrv
        }

        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .hour, value: -24, to: now) else {
            return HealthKitMockData.hrv
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let average = statistics?.averageQuantity() else {
                    continuation.resume(returning: HealthKitMockData.hrv)
                    return
                }

                let value = average.doubleValue(for: .secondUnit(with: .milli))
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate

    func fetchHeartRate() async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return HealthKitMockData.heartRate
        }

        let value = try await fetchLatestQuantity(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
        return value ?? HealthKitMockData.heartRate
    }

    // MARK: - Body Temperature

    func fetchBodyTemperature() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else {
            return nil
        }

        return try await fetchLatestQuantity(type: type, unit: .degreeCelsius())
    }

    // MARK: - Oxygen Saturation

    func fetchOxygenSaturation() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            return nil
        }

        let value = try await fetchLatestQuantity(type: type, unit: .percent())
        return value.map { $0 * 100 }
    }

    // MARK: - Respiratory Rate

    func fetchRespiratoryRate() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            return nil
        }

        return try await fetchLatestQuantity(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    // MARK: - VO2 Max

    func fetchVO2Max() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            return nil
        }

        // VO2 Max is measured in mL/(kg·min)
        let unit = HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        return try await fetchLatestQuantity(type: type, unit: unit)
    }

    // MARK: - Wrist Temperature (Apple Watch)

    func fetchWristTemperature() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature) else {
            return nil
        }

        return try await fetchLatestQuantity(type: type, unit: .degreeCelsius())
    }

    // MARK: - Stand Hours

    func fetchStandHours() async throws -> Int {
        guard let standType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) else {
            return 0
        }

        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: standType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Count hours where user stood
                let standCount = samples.filter { $0.value == HKCategoryValueAppleStandHour.stood.rawValue }.count
                continuation.resume(returning: standCount)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Weekly HRV (for trend analysis)

    func fetchWeeklyHRV() async throws -> [Double] {
        var hrvValues: [Double] = []
        let calendar = Calendar.current

        for daysAgo in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
                continue
            }

            if let hrv = try await fetchDayHRV(for: date) {
                hrvValues.append(hrv)
            }
        }

        // Return mock data if no values found
        if hrvValues.isEmpty {
            return [42, 45, 43, 48, 50, 52, 55]
        }

        return hrvValues
    }

    // MARK: - Resting HR Trend (for trend analysis)

    func fetchRestingHRTrend() async throws -> [Double] {
        var rhrValues: [Double] = []
        let calendar = Calendar.current

        for daysAgo in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
                continue
            }

            if let rhr = try await fetchDayRestingHeartRate(for: date) {
                rhrValues.append(rhr)
            }
        }

        // Return mock data if no values found
        if rhrValues.isEmpty {
            return [60, 59, 58, 58, 57, 58, 58]
        }

        return rhrValues
    }

    // MARK: - Steps

    func fetchStepCount() async throws -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return HealthKitMockData.steps
        }

        let value = try await fetchTodaySum(type: type, unit: .count())
        return value.map { Int($0) } ?? HealthKitMockData.steps
    }

    // MARK: - Active Calories

    func fetchActiveCalories() async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return HealthKitMockData.calories
        }

        let value = try await fetchTodaySum(type: type, unit: .kilocalorie())
        return value ?? HealthKitMockData.calories
    }

    // MARK: - Sleep Analysis (detailed)

    func fetchSleepAnalysis() async throws -> SleepData {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return HealthKitMockData.sleepData
        }

        let calendar = Calendar.current
        let now = Date()

        // Look for sleep from 6 PM yesterday to now
        guard let yesterdayEvening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now.addingTimeInterval(-86400)) else {
            return HealthKitMockData.sleepData
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterdayEvening,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: HealthKitMockData.sleepData)
                    return
                }

                var deepMinutes = 0
                var remMinutes = 0
                var lightMinutes = 0
                var awakeMinutes = 0
                var bedtime: Date?
                var wakeTime: Date?

                for sample in samples {
                    let duration = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)

                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepMinutes += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remMinutes += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        lightMinutes += duration
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        awakeMinutes += duration
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        if bedtime == nil {
                            bedtime = sample.startDate
                        }
                        wakeTime = sample.endDate
                    default:
                        break
                    }
                }

                let totalMinutes = deepMinutes + remMinutes + lightMinutes
                let totalWithAwake = totalMinutes + awakeMinutes
                let efficiency = totalWithAwake > 0 ? (totalMinutes * 100) / totalWithAwake : 0

                let sleepData = SleepData(
                    totalMinutes: totalMinutes,
                    deepMinutes: deepMinutes,
                    remMinutes: remMinutes,
                    lightMinutes: lightMinutes,
                    awakeMinutes: awakeMinutes,
                    efficiency: efficiency,
                    bedtime: bedtime,
                    wakeTime: wakeTime
                )

                // Return mock if no actual sleep data
                if totalMinutes == 0 {
                    continuation.resume(returning: HealthKitMockData.sleepData)
                } else {
                    continuation.resume(returning: sleepData)
                }
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Weekly Data for Trends

    func fetchWeeklyRecoveryData() async throws -> [DailyHealthData] {
        let calendar = Calendar.current
        var weeklyData: [DailyHealthData] = []

        for daysAgo in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
                continue
            }

            async let rhr = fetchDayRestingHeartRate(for: date)
            async let hrv = fetchDayHRV(for: date)
            async let sleep = fetchDaySleep(for: date)
            async let steps = fetchDaySteps(for: date)
            async let calories = fetchDayCalories(for: date)

            let restingHR = try? await rhr
            let hrvValue = try? await hrv
            let sleepHours = try? await sleep
            let stepsValue = try? await steps
            let caloriesValue = try? await calories

            // Calculate recovery score based on available data
            var recoveryScore: Int? = nil
            if let rhr = restingHR, let hrv = hrvValue {
                let sleepDuration: TimeInterval? = sleepHours.map { $0 * 3600 }
                recoveryScore = HealthCalculations.calculateRecoveryScore(
                    hrv: hrv,
                    restingHeartRate: rhr,
                    sleepDuration: sleepDuration,
                    sleepQuality: nil
                )
            }

            let dailyData = DailyHealthData(
                date: date,
                restingHeartRate: restingHR,
                hrv: hrvValue,
                sleepHours: sleepHours,
                steps: stepsValue,
                calories: caloriesValue,
                recoveryScore: recoveryScore
            )

            weeklyData.append(dailyData)
        }

        // Return mock data if all values are nil
        if weeklyData.allSatisfy({ $0.restingHeartRate == nil && $0.hrv == nil && $0.steps == nil }) {
            return HealthKitMockData.weeklyData
        }

        return weeklyData.reversed() // Oldest first
    }

    // MARK: - Day-specific fetching helpers

    private func fetchDayRestingHeartRate(for date: Date) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }
        return try await fetchDayAverage(type: type, unit: HKUnit.count().unitDivided(by: .minute()), for: date)
    }

    private func fetchDayHRV(for date: Date) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }
        return try await fetchDayAverage(type: type, unit: .secondUnit(with: .milli), for: date)
    }

    private func fetchDaySleep(for date: Date) async throws -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        // For sleep, we need to look at the previous evening
        guard let previousEvening = calendar.date(byAdding: .hour, value: -6, to: startOfDay) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: previousEvening,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let sleepSamples = samples.filter { sample in
                    sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }

                let totalSeconds = sleepSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }

                let hours = totalSeconds / 3600
                continuation.resume(returning: hours > 0 ? hours : nil)
            }

            healthStore.execute(query)
        }
    }

    private func fetchDaySteps(for date: Date) async throws -> Int? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }
        let value = try await fetchDaySum(type: type, unit: .count(), for: date)
        return value.map { Int($0) }
    }

    private func fetchDayCalories(for date: Date) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        return try await fetchDaySum(type: type, unit: .kilocalorie(), for: date)
    }

    private func fetchDayAverage(type: HKQuantityType, unit: HKUnit, for date: Date) async throws -> Double? {
        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let average = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: average.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    private func fetchDaySum(type: HKQuantityType, unit: HKUnit, for date: Date) async throws -> Double? {
        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: sum.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Generic Helper Methods

    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func fetchTodaySum(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: sum.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch All Data (for Dashboard)

    struct DashboardData {
        let restingHR: Double
        let hrv: Double
        let heartRate: Double
        let sleepData: SleepData
        let steps: Int
        let calories: Double
        let bodyTemp: Double?
        let oxygenSat: Double?
        let respiratoryRate: Double?
        let vo2Max: Double?
        let wristTemperature: Double?
        let standHours: Int
        let weeklyHRV: [Double]
        let restingHRTrend: [Double]
    }

    func fetchAllDashboardData() async throws -> DashboardData {
        async let restingHR = fetchRestingHeartRate()
        async let hrv = fetchHRV()
        async let heartRate = fetchHeartRate()
        async let sleepData = fetchSleepAnalysis()
        async let steps = fetchStepCount()
        async let calories = fetchActiveCalories()
        async let bodyTemp = fetchBodyTemperature()
        async let oxygenSat = fetchOxygenSaturation()
        async let respiratoryRate = fetchRespiratoryRate()
        async let vo2Max = fetchVO2Max()
        async let wristTemp = fetchWristTemperature()
        async let standHours = fetchStandHours()
        async let weeklyHRV = fetchWeeklyHRV()
        async let restingHRTrend = fetchRestingHRTrend()

        return try await DashboardData(
            restingHR: restingHR,
            hrv: hrv,
            heartRate: heartRate,
            sleepData: sleepData,
            steps: steps,
            calories: calories,
            bodyTemp: bodyTemp,
            oxygenSat: oxygenSat,
            respiratoryRate: respiratoryRate,
            vo2Max: vo2Max,
            wristTemperature: wristTemp,
            standHours: standHours,
            weeklyHRV: weeklyHRV,
            restingHRTrend: restingHRTrend
        )
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "Permission to access health data was denied"
        case .dataNotAvailable:
            return "The requested health data is not available"
        }
    }
}
