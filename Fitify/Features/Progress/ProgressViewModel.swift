//
//  ProgressViewModel.swift
//  Fitify
//

import Foundation
import SwiftData

// MARK: - Data Point Models

struct StrengthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let estimatedOneRM: Double
    let totalSets: Int
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let tonnage: Double  // в тоннах
}

struct BodyWeightEntry: Identifiable {
    let id = UUID()
    let date: Date
    let weightKg: Double
}

struct OneRMResult: Identifiable {
    let id = UUID()
    let exerciseName: String
    let bestSetWeight: Double
    let bestSetReps: Int
    let estimatedOneRM: Double
    let date: Date
}

// MARK: - BodyWeightLog SwiftData Model

@Model
final class BodyWeightLog {
    var date: Date
    var weightKg: Double
    var notes: String

    init(weightKg: Double, date: Date = Date(), notes: String = "") {
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
    }
}

// MARK: - ProgressViewModel

@Observable
class ProgressViewModel {
    var workoutLogs: [WorkoutLog] = []
    var selectedExercise: Exercise? = nil
    var bodyWeightEntries: [BodyWeightEntry] = []
    var timeRange: TimeRange = .threeMonths

    enum TimeRange: String, CaseIterable {
        case oneMonth = "1М"
        case threeMonths = "3М"
        case sixMonths = "6М"
        case allTime = "Весь час"

        var days: Int {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .allTime: return 3650
            }
        }
    }

    // MARK: - Strength Progress

    /// Returns strength data points for a specific exercise
    func strengthData(for exerciseName: String) -> [StrengthDataPoint] {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -timeRange.days, to: Date()
        )!

        return workoutLogs
            .filter { $0.date > cutoff }
            .compactMap { log -> StrengthDataPoint? in
                let sets = log.completedSets
                    .filter { $0.exerciseName == exerciseName && $0.isCompleted }
                guard !sets.isEmpty else { return nil }
                let maxWeight = sets.map { $0.weightKg }.max() ?? 0

                // 1RM по Brzycki: weight × (36 / (37 - reps))
                guard let bestSet = sets.max(by: { $0.weightKg < $1.weightKg }) else {
                    return nil
                }
                let oneRM = calculateOneRM(weight: bestSet.weightKg, reps: bestSet.reps)

                return StrengthDataPoint(
                    date: log.date,
                    maxWeight: maxWeight,
                    estimatedOneRM: oneRM,
                    totalSets: sets.count
                )
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Volume Load

    /// Returns weekly volume data in tonnes
    func weeklyVolumeData() -> [VolumeDataPoint] {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -timeRange.days, to: Date()
        )!

        let filtered = workoutLogs.filter { $0.date > cutoff }
        var weeklyData: [Date: Double] = [:]

        for log in filtered {
            let weekStart = Calendar.current.startOfWeek(for: log.date)
            let volume = log.completedSets
                .filter { $0.isCompleted }
                .reduce(0.0) { $0 + $1.weightKg * Double($1.reps) } / 1000.0 // в тоннах
            weeklyData[weekStart, default: 0] += volume
        }

        return weeklyData.map { VolumeDataPoint(weekStart: $0.key, tonnage: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    // MARK: - Exercises With Data

    /// Returns unique exercise names that have logged data
    func exercisesWithData() -> [String] {
        let names = workoutLogs
            .flatMap { $0.completedSets }
            .filter { $0.isCompleted }
            .map { $0.exerciseName }

        return Array(Set(names)).sorted()
    }

    // MARK: - Top 1RM Results

    /// Returns top 1RM results from all workout logs
    func topOneRMResults() -> [OneRMResult] {
        var byExercise: [String: OneRMResult] = [:]

        for log in workoutLogs {
            for set in log.completedSets where set.isCompleted && set.reps > 0 {
                let oneRM = calculateOneRM(weight: set.weightKg, reps: set.reps)
                let existing = byExercise[set.exerciseName]
                if existing == nil || oneRM > existing!.estimatedOneRM {
                    byExercise[set.exerciseName] = OneRMResult(
                        exerciseName: set.exerciseName,
                        bestSetWeight: set.weightKg,
                        bestSetReps: set.reps,
                        estimatedOneRM: oneRM,
                        date: log.date
                    )
                }
            }
        }

        return Array(byExercise.values).sorted { $0.estimatedOneRM > $1.estimatedOneRM }
    }

    // MARK: - 1RM Calculation

    /// Brzycki formula: weight × 36 / (37 - reps)
    func calculateOneRM(weight: Double, reps: Int) -> Double {
        guard reps > 0 && reps < 37 else { return weight }
        if reps == 1 { return weight }
        return weight * 36.0 / (37.0 - Double(reps))
    }

    // MARK: - Data Loading

    func loadData(from context: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\.date)]
        )
        workoutLogs = (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
