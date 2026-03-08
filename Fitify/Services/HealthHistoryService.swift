//
//  HealthHistoryService.swift
//  Fitify
//

import Foundation
import SwiftData
import HealthKit

// MARK: - Data Models

struct HealthHistory: Codable {
    var dailySnapshots: [DailyHealthRecord]
    var baseline: UserBaseline
    var fetchedAt: Date

    var daysCount: Int {
        dailySnapshots.count
    }

    static var empty: HealthHistory {
        HealthHistory(
            dailySnapshots: [],
            baseline: .empty,
            fetchedAt: Date()
        )
    }
}

struct DailyHealthRecord: Codable, Identifiable {
    var id: Date { date }
    var date: Date
    var restingHR: Double?
    var hrv: Double?
    var sleepHours: Double?
    var deepSleepMinutes: Int?
    var remSleepMinutes: Int?
    var steps: Int?
    var activeCalories: Double?
    var oxygenSaturation: Double?
    var respiratoryRate: Double?
    var wristTemperature: Double?
    var workoutMinutes: Int?

    var hasData: Bool {
        restingHR != nil || hrv != nil || sleepHours != nil || steps != nil
    }
}

struct UserBaseline: Codable {
    // Median values (robust to outliers)
    var medianRestingHR: Double
    var medianHRV: Double
    var medianSleepHours: Double
    var medianSteps: Int
    var medianActiveCalories: Double

    // Standard deviations (for anomaly detection)
    var stdevHRV: Double
    var stdevRestingHR: Double

    static var empty: UserBaseline {
        UserBaseline(
            medianRestingHR: 60,
            medianHRV: 45,
            medianSleepHours: 7,
            medianSteps: 8000,
            medianActiveCalories: 400,
            stdevHRV: 10,
            stdevRestingHR: 5
        )
    }

    // Anomaly detection: value is > 1.5 standard deviations from baseline
    func isAnomalous(current: Double, baseline: Double, stdev: Double) -> Bool {
        guard stdev > 0 else { return false }
        return abs(current - baseline) > 1.5 * stdev
    }

    func isHRVAnomalous(_ currentHRV: Double) -> Bool {
        isAnomalous(current: currentHRV, baseline: medianHRV, stdev: stdevHRV)
    }

    func isRestingHRAnomalous(_ currentRHR: Double) -> Bool {
        isAnomalous(current: currentRHR, baseline: medianRestingHR, stdev: stdevRestingHR)
    }
}

// MARK: - SwiftData Cache Model

@Model
final class CachedHealthHistory {
    var jsonData: Data
    var lastUpdated: Date
    var daysCount: Int

    init(jsonData: Data, lastUpdated: Date, daysCount: Int) {
        self.jsonData = jsonData
        self.lastUpdated = lastUpdated
        self.daysCount = daysCount
    }

    var isStale: Bool {
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdated) / 3600
        return hoursSinceUpdate >= 24
    }

    func decode() -> HealthHistory? {
        try? JSONDecoder().decode(HealthHistory.self, from: jsonData)
    }
}

// MARK: - Health History Service

@Observable
final class HealthHistoryService {
    static let shared = HealthHistoryService()

    private let healthStore = HKHealthStore()
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    var syncProgress: Double = 0
    var isSyncing = false
    var lastError: String?

    private init() {
        setupSwiftData()
    }

    private func setupSwiftData() {
        do {
            let schema = Schema([CachedHealthHistory.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
            if let container = modelContainer {
                modelContext = ModelContext(container)
            }
        } catch {
            lastError = "Failed to setup cache: \(error.localizedDescription)"
        }
    }

    // MARK: - Public API

    /// Fetches health history, using cache if fresh (< 24h), otherwise fetches from HealthKit
    func fetchHealthHistory(forceRefresh: Bool = false) async -> HealthHistory {
        // Check cache first
        if !forceRefresh, let cached = loadFromCache(), !cached.isStale {
            if let history = cached.decode() {
                return history
            }
        }

        // Fetch fresh data from HealthKit
        return await fetchFullHealthHistory()
    }

    /// Fetches 90 days of health data from HealthKit
    func fetchFullHealthHistory() async -> HealthHistory {
        guard HKHealthStore.isHealthDataAvailable() else {
            return useMockHistory()
        }

        isSyncing = true
        syncProgress = 0
        lastError = nil
        defer { isSyncing = false }

        let calendar = Calendar.current
        let today = Date()
        let daysToFetch = 90

        var dailyRecords: [DailyHealthRecord] = []

        // Fetch data day by day
        for dayOffset in 0..<daysToFetch {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            let record = await fetchDayRecord(for: date)
            dailyRecords.append(record)

            // Update progress
            syncProgress = Double(dayOffset + 1) / Double(daysToFetch)
        }

        // Reverse to have oldest first
        dailyRecords.reverse()

        // Calculate baseline from collected data
        let baseline = calculateBaseline(from: dailyRecords)

        let history = HealthHistory(
            dailySnapshots: dailyRecords,
            baseline: baseline,
            fetchedAt: Date()
        )

        // Save to cache
        saveToCache(history)

        return history
    }

    // MARK: - Day Record Fetching

    private func fetchDayRecord(for date: Date) async -> DailyHealthRecord {
        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return DailyHealthRecord(date: date)
        }

        async let restingHR = fetchDayAverage(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            start: startOfDay,
            end: endOfDay
        )

        async let hrv = fetchDayAverage(
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            start: startOfDay,
            end: endOfDay
        )

        async let steps = fetchDaySum(
            identifier: .stepCount,
            unit: .count(),
            start: startOfDay,
            end: endOfDay
        )

        async let calories = fetchDaySum(
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            start: startOfDay,
            end: endOfDay
        )

        async let oxygenSat = fetchDayAverage(
            identifier: .oxygenSaturation,
            unit: .percent(),
            start: startOfDay,
            end: endOfDay
        )

        async let respRate = fetchDayAverage(
            identifier: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            start: startOfDay,
            end: endOfDay
        )

        async let wristTemp = fetchDayAverage(
            identifier: .appleSleepingWristTemperature,
            unit: .degreeCelsius(),
            start: startOfDay,
            end: endOfDay
        )

        async let sleepData = fetchDaySleep(start: startOfDay, end: endOfDay)
        async let workoutMins = fetchDayWorkoutMinutes(start: startOfDay, end: endOfDay)

        let sleep = await sleepData

        return DailyHealthRecord(
            date: date,
            restingHR: await restingHR,
            hrv: await hrv,
            sleepHours: sleep.totalHours,
            deepSleepMinutes: sleep.deepMinutes,
            remSleepMinutes: sleep.remMinutes,
            steps: await steps.map { Int($0) },
            activeCalories: await calories,
            oxygenSaturation: await oxygenSat.map { $0 * 100 },
            respiratoryRate: await respRate,
            wristTemperature: await wristTemp,
            workoutMinutes: await workoutMins
        )
    }

    // MARK: - HealthKit Queries

    private func fetchDayAverage(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let value = statistics?.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchDaySum(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchDaySleep(start: Date, end: Date) async -> (totalHours: Double?, deepMinutes: Int?, remMinutes: Int?) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (nil, nil, nil)
        }

        // Look for sleep starting from previous evening
        let calendar = Calendar.current
        guard let previousEvening = calendar.date(byAdding: .hour, value: -6, to: start) else {
            return (nil, nil, nil)
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: previousEvening,
            end: end,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: (nil, nil, nil))
                    return
                }

                var deepMinutes = 0
                var remMinutes = 0
                var totalMinutes = 0

                for sample in samples {
                    let duration = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)

                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepMinutes += duration
                        totalMinutes += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remMinutes += duration
                        totalMinutes += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        totalMinutes += duration
                    default:
                        break
                    }
                }

                let totalHours = totalMinutes > 0 ? Double(totalMinutes) / 60.0 : nil
                continuation.resume(returning: (
                    totalHours,
                    deepMinutes > 0 ? deepMinutes : nil,
                    remMinutes > 0 ? remMinutes : nil
                ))
            }
            healthStore.execute(query)
        }
    }

    private func fetchDayWorkoutMinutes(start: Date, end: Date) async -> Int? {
        let workoutType = HKObjectType.workoutType()

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: nil)
                    return
                }

                let totalMinutes = workouts.reduce(0) { total, workout in
                    total + Int(workout.duration / 60)
                }

                continuation.resume(returning: totalMinutes > 0 ? totalMinutes : nil)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Baseline Calculation

    private func calculateBaseline(from records: [DailyHealthRecord]) -> UserBaseline {
        // Extract non-nil values
        let restingHRValues = records.compactMap { $0.restingHR }
        let hrvValues = records.compactMap { $0.hrv }
        let sleepValues = records.compactMap { $0.sleepHours }
        let stepsValues = records.compactMap { $0.steps }
        let caloriesValues = records.compactMap { $0.activeCalories }

        // If no data, return default baseline
        guard !restingHRValues.isEmpty || !hrvValues.isEmpty else {
            return .empty
        }

        return UserBaseline(
            medianRestingHR: median(restingHRValues) ?? 60,
            medianHRV: median(hrvValues) ?? 45,
            medianSleepHours: median(sleepValues) ?? 7,
            medianSteps: Int(median(stepsValues.map { Double($0) }) ?? 8000),
            medianActiveCalories: median(caloriesValues) ?? 400,
            stdevHRV: standardDeviation(hrvValues) ?? 10,
            stdevRestingHR: standardDeviation(restingHRValues) ?? 5
        )
    }

    /// Calculate median (robust to outliers)
    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }

    /// Calculate standard deviation
    private func standardDeviation(_ values: [Double]) -> Double? {
        guard values.count > 1 else { return nil }

        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count - 1)

        return sqrt(variance)
    }

    // MARK: - Cache Management

    private func loadFromCache() -> CachedHealthHistory? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<CachedHealthHistory>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    private func saveToCache(_ history: HealthHistory) {
        guard let context = modelContext else { return }

        // Delete old cache
        do {
            try context.delete(model: CachedHealthHistory.self)
        } catch {
            // Ignore deletion errors
        }

        // Save new cache
        do {
            let jsonData = try JSONEncoder().encode(history)
            let cached = CachedHealthHistory(
                jsonData: jsonData,
                lastUpdated: Date(),
                daysCount: history.daysCount
            )
            context.insert(cached)
            try context.save()
        } catch {
            lastError = "Failed to cache history: \(error.localizedDescription)"
        }
    }

    /// Check if cache needs refresh
    func needsRefresh() -> Bool {
        guard let cached = loadFromCache() else { return true }
        return cached.isStale
    }

    /// Clear all cached data
    func clearCache() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: CachedHealthHistory.self)
            try context.save()
        } catch {
            lastError = "Failed to clear cache: \(error.localizedDescription)"
        }
    }

    // MARK: - Mock Data

    private func useMockHistory() -> HealthHistory {
        let calendar = Calendar.current
        let today = Date()

        var records: [DailyHealthRecord] = []

        for dayOffset in (0..<90).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            // Generate realistic mock data with some variation
            let baseHRV = 45.0 + Double.random(in: -15...15)
            let baseRHR = 58.0 + Double.random(in: -8...8)
            let baseSleep = 7.0 + Double.random(in: -2...1.5)
            let baseSteps = 8000 + Int.random(in: -4000...4000)

            records.append(DailyHealthRecord(
                date: date,
                restingHR: baseRHR,
                hrv: max(20, baseHRV),
                sleepHours: max(4, baseSleep),
                deepSleepMinutes: Int.random(in: 45...90),
                remSleepMinutes: Int.random(in: 60...120),
                steps: max(1000, baseSteps),
                activeCalories: Double.random(in: 200...600),
                oxygenSaturation: Double.random(in: 96...99),
                respiratoryRate: Double.random(in: 12...18),
                wristTemperature: Double.random(in: -0.5...0.5),
                workoutMinutes: Bool.random() ? Int.random(in: 30...90) : nil
            ))
        }

        let baseline = calculateBaseline(from: records)

        return HealthHistory(
            dailySnapshots: records,
            baseline: baseline,
            fetchedAt: Date()
        )
    }
}

// MARK: - Anomaly Detection Helper

extension HealthHistory {
    /// Check if current HRV is anomalously low
    func isHRVAnomalous(_ currentHRV: Double) -> Bool {
        baseline.isHRVAnomalous(currentHRV)
    }

    /// Check if current resting HR is anomalously high
    func isRestingHRAnomalous(_ currentRHR: Double) -> Bool {
        baseline.isRestingHRAnomalous(currentRHR)
    }

    /// Get trend direction for a metric over last N days
    func trend(for keyPath: KeyPath<DailyHealthRecord, Double?>, lastDays: Int = 7) -> TrendDirection {
        let recentRecords = dailySnapshots.suffix(lastDays)
        let values = recentRecords.compactMap { $0[keyPath: keyPath] }

        guard values.count >= 3 else { return .insufficient }

        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))

        guard !firstHalf.isEmpty, !secondHalf.isEmpty else { return .insufficient }

        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let change = (secondAvg - firstAvg) / firstAvg

        if change > 0.05 { return .improving }
        if change < -0.05 { return .declining }
        return .stable
    }
}

enum TrendDirection {
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
}
