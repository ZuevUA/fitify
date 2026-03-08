//
//  ProgressionEngine.swift
//  Fitify
//
//  Jeff Nippard-based progression algorithm for weight recommendations
//

import Foundation

// MARK: - Progression Engine

struct ProgressionEngine {

    /// Main function - calculate next weight after workout
    static func calculateNextWeight(
        exercise: Exercise,
        completedSets: [CompletedSet],
        history: [WorkoutLog] = []
    ) -> ProgressionRecommendation {

        guard !completedSets.isEmpty else {
            return ProgressionRecommendation(weight: 0, reason: .noData, detail: "Немає даних")
        }

        let totalSets = completedSets.count
        let completedCount = completedSets.filter { $0.isCompleted }.count
        let avgReps = completedSets.map { $0.reps }.reduce(0, +) / max(totalSets, 1)
        let avgRIR = completedSets.map { $0.rir }.reduce(0, +) / max(totalSets, 1)
        let currentWeight = completedSets.first?.weightKg ?? 0

        // Nippard Rules:

        // 1. Not all sets completed - reduce weight
        if completedCount < totalSets {
            let reduction = weightStep(for: currentWeight) * -1
            return ProgressionRecommendation(
                weight: max(0, currentWeight + reduction),
                reason: .reducedIncomplete,
                detail: "Виконано \(completedCount)/\(totalSets) підходів"
            )
        }

        // 2. Average RIR = 0 (training to failure) - maintain weight
        if avgRIR == 0 {
            return ProgressionRecommendation(
                weight: currentWeight,
                reason: .maintainHighIntensity,
                detail: "RIR 0 — занадто близько до відмови. Залиш вагу"
            )
        }

        // 3. All reps at max + RIR >= 2 → INCREASE
        let allAtMax = completedSets.allSatisfy { $0.reps >= exercise.repsMax }
        if allAtMax && avgRIR >= 2 {
            let increase = weightStep(for: currentWeight)
            return ProgressionRecommendation(
                weight: currentWeight + increase,
                reason: .increase,
                detail: "+\(formatWeight(increase))кг — досяг верхньої межі повторень з запасом"
            )
        }

        // 4. Most reps below minimum → reduce weight
        let belowMin = completedSets.filter { $0.reps < exercise.repsMin }.count
        if belowMin > totalSets / 2 {
            let reduction = weightStep(for: currentWeight)
            return ProgressionRecommendation(
                weight: max(0, currentWeight - reduction),
                reason: .reduce,
                detail: "Повторення нижче мінімуму (\(exercise.repsMin))"
            )
        }

        // 5. Reps normal but RIR 1-2 → maintain and add reps
        if avgReps < exercise.repsMax && avgRIR <= 2 {
            return ProgressionRecommendation(
                weight: currentWeight,
                reason: .maintainAddReps,
                detail: "Залиш вагу — намагайся додати 1-2 повторення"
            )
        }

        // Default: maintain weight
        return ProgressionRecommendation(
            weight: currentWeight,
            reason: .maintain,
            detail: "Продовжуй з тією ж вагою"
        )
    }

    /// Weight step based on current weight
    static func weightStep(for weight: Double) -> Double {
        switch weight {
        case 0..<20:  return 1.0    // light dumbbells
        case 20..<60: return 2.5    // medium weights
        default:      return 5.0    // heavy weights
        }
    }

    /// Check if deload is needed
    static func shouldDeload(logs: [WorkoutLog], weeks: Int = 4) -> DeloadRecommendation {
        let cutoff = Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: Date())!
        let recentLogs = logs.filter { $0.date > cutoff }

        // Calculate average RIR from recent workouts
        let allSets = recentLogs.flatMap { $0.completedSets }
        guard !allSets.isEmpty else { return .notNeeded }

        let avgRIR = Double(allSets.map { $0.rir }.reduce(0, +)) / Double(allSets.count)

        // Low average RIR = overtrained
        if recentLogs.count >= 4 * 4 && avgRIR < 1.5 {
            return .recommended(reason: "Низький середній RIR — ознака перевтоми")
        }

        // More than 5 weeks without deload
        if recentLogs.count >= 4 * 5 {
            return .recommended(reason: "Більше 5 тижнів без розвантаження")
        }

        return .notNeeded
    }

    /// Calculate volume progress between workouts
    static func calculateVolumeProgress(
        current: WorkoutLog,
        previous: WorkoutLog?
    ) -> Double {
        let currentVolume = current.totalVolume
        guard let prev = previous else { return 0 }
        let prevVolume = prev.totalVolume

        guard prevVolume > 0 else { return 0 }
        return ((currentVolume - prevVolume) / prevVolume) * 100
    }

    private static func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Progression Recommendation

struct ProgressionRecommendation {
    let weight: Double
    let reason: ProgressionReason
    let detail: String

    init(weight: Double, reason: ProgressionReason, detail: String = "") {
        self.weight = weight
        self.reason = reason
        self.detail = detail
    }
}

enum ProgressionReason {
    case increase
    case maintain
    case maintainAddReps
    case maintainHighIntensity
    case reduce
    case reducedIncomplete
    case noData

    var emoji: String {
        switch self {
        case .increase: return "↑"
        case .reduce, .reducedIncomplete: return "↓"
        default: return "→"
        }
    }

    var colorName: String {
        switch self {
        case .increase: return "green"
        case .reduce, .reducedIncomplete: return "red"
        default: return "gray"
        }
    }

    var displayText: String {
        switch self {
        case .increase: return "Збільшити"
        case .maintain: return "Залишити"
        case .maintainAddReps: return "Додати повтори"
        case .maintainHighIntensity: return "Залишити (високий RIR)"
        case .reduce: return "Зменшити"
        case .reducedIncomplete: return "Зменшити (не завершено)"
        case .noData: return "Немає даних"
        }
    }
}

// MARK: - Deload Recommendation

enum DeloadRecommendation {
    case recommended(reason: String)
    case notNeeded

    var isRecommended: Bool {
        if case .recommended = self { return true }
        return false
    }

    var reason: String? {
        if case .recommended(let reason) = self { return reason }
        return nil
    }
}

// MARK: - Weekly Report Model

struct WeeklyReport: Codable {
    let weekSummary: String
    let topProgress: [ExerciseProgress]
    let concerns: [String]
    let nextWeekFocus: String
    let deloadNeeded: Bool
    let motivationalNote: String

    struct ExerciseProgress: Codable, Identifiable {
        var id: String { exercise }
        let exercise: String
        let insight: String
    }
}
