//
//  WorkoutSummaryView.swift
//  Fitify
//
//  Post-workout summary with progression recommendations
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    let workoutLog: WorkoutLog
    let workoutDay: WorkoutDay
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    // Calculate recommendations for each exercise
    var progressionResults: [UUID: ProgressionRecommendation] {
        var results: [UUID: ProgressionRecommendation] = [:]
        for exercise in workoutDay.exercises {
            let sets = workoutLog.completedSets.filter { $0.exerciseId == exercise.id }
            results[exercise.id] = ProgressionEngine.calculateNextWeight(
                exercise: exercise,
                completedSets: sets,
                history: []
            )
        }
        return results
    }

    var totalVolume: Double {
        workoutLog.completedSets
            .filter { $0.isCompleted }
            .reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    var completedSetsCount: Int {
        workoutLog.completedSets.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("Тренування завершено!")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text(workoutDay.dayName)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // Stats
                        HStack(spacing: 16) {
                            SummaryStatBox(
                                value: "\(workoutLog.durationMinutes) хв",
                                label: "Тривалість",
                                icon: "timer"
                            )
                            SummaryStatBox(
                                value: formatVolume(totalVolume),
                                label: "Загальний об'єм",
                                icon: "scalemass"
                            )
                            SummaryStatBox(
                                value: "\(completedSetsCount)",
                                label: "Підходів",
                                icon: "number"
                            )
                        }
                        .padding(.horizontal)

                        // Next workout recommendations
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.up.forward.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Наступне тренування")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)

                            ForEach(workoutDay.exercises) { exercise in
                                if let rec = progressionResults[exercise.id] {
                                    NextWorkoutRow(
                                        exercise: exercise,
                                        recommendation: rec
                                    )
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(Color(white: 0.06))
                        .cornerRadius(20)
                        .padding(.horizontal)

                        // Save recommendations button
                        Button {
                            saveRecommendations()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Зберегти рекомендації")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)

                        Button("Закрити") { dismiss() }
                            .foregroundColor(.gray)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    func saveRecommendations() {
        for exercise in workoutDay.exercises {
            if let rec = progressionResults[exercise.id], rec.weight > 0 {
                exercise.suggestedWeightKg = rec.weight
            }
        }
        try? modelContext.save()
        dismiss()
    }

    func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fт", volume / 1000)
        }
        return "\(Int(volume)) кг"
    }
}

// MARK: - Next Workout Row

struct NextWorkoutRow: View {
    let exercise: Exercise
    let recommendation: ProgressionRecommendation

    var reasonColor: Color {
        switch recommendation.reason {
        case .increase: return .green
        case .reduce, .reducedIncomplete: return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(recommendation.detail)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
            HStack(spacing: 4) {
                Text(recommendation.reason.emoji)
                    .font(.title3)
                Text(recommendation.weight > 0 ? "\(formatWeight(recommendation.weight)) кг" : "—")
                    .font(.headline.bold())
            }
            .foregroundColor(reasonColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Summary Stat Box

struct SummaryStatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(white: 0.08))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    let exercise = Exercise(
        name: "Жим штанги лежачи",
        sets: 4,
        repsMin: 6,
        repsMax: 10,
        rir: 2
    )

    let day = WorkoutDay(
        dayName: "Push A",
        focus: "Груди, Плечі",
        exercises: [exercise]
    )

    let set = CompletedSet(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        setNumber: 1,
        weightKg: 80,
        reps: 10,
        rir: 2,
        isCompleted: true
    )

    let log = WorkoutLog(
        workoutDayId: day.id,
        workoutDayName: day.dayName,
        durationMinutes: 55,
        totalVolume: 3200,
        completedSets: [set]
    )

    return WorkoutSummaryView(workoutLog: log, workoutDay: day)
        .modelContainer(for: [WorkoutLog.self])
}
