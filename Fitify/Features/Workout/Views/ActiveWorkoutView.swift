//
//  ActiveWorkoutView.swift
//  Fitify
//
//  Active workout tracking view - Lift App style
//

import SwiftUI
import SwiftData
import Combine
import UIKit

struct ActiveWorkoutView: View {
    let workoutDay: WorkoutDay
    var isLightWorkout: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Set tracking - dictionary [exerciseId: [ActiveSetData]]
    @State private var setData: [UUID: [ActiveSetData]] = [:]
    @State private var startTime = Date()
    @State private var elapsedSeconds = 0
    @State private var restTimer: Int? = nil
    @State private var showFinishAlert = false
    @State private var showCancelAlert = false
    @State private var showSummary = false
    @State private var currentLog: WorkoutLog?

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    struct ActiveSetData: Identifiable {
        let id = UUID()
        var weight: String = ""
        var reps: String = ""
        var rir: Int = 2
        var isCompleted: Bool = false
        var suggestedWeight: String? = nil
    }

    /// Adjusted sets count for light workout (70% of original)
    private func adjustedSetsCount(for exercise: Exercise) -> Int {
        if isLightWorkout {
            return max(1, Int(Double(exercise.sets) * 0.7))
        }
        return exercise.sets
    }

    /// Adjusted weight suggestion for light workout (80% of original)
    private func adjustedWeight(_ weight: Double) -> Double {
        if isLightWorkout {
            return weight * 0.8
        }
        return weight
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Timer bar at top
                    WorkoutTimerBar(
                        elapsed: elapsedSeconds,
                        restTimer: restTimer
                    )

                    // Light workout indicator
                    if isLightWorkout {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.orange)
                            Text("Легке тренування — зменшено підходи та вагу")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.15))
                    }

                    // Exercise list
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(workoutDay.exercises) { exercise in
                                ExerciseLogCard(
                                    exercise: exercise,
                                    sets: Binding(
                                        get: { setData[exercise.id] ?? initSets(exercise) },
                                        set: { setData[exercise.id] = $0 }
                                    ),
                                    onSetCompleted: { startRestTimer(exercise.restSeconds) }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }

                // Rest timer overlay
                if let rest = restTimer, rest > 0 {
                    RestTimerOverlay(
                        timeRemaining: rest,
                        onSkip: { restTimer = nil }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { showCancelAlert = true }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .principal) {
                    Text(workoutDay.dayName)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Завершити") { finishWorkout() }
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .onAppear { initAllSets() }
        .onReceive(timer) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            if let rest = restTimer, rest > 0 {
                restTimer = rest - 1
            }
        }
        .alert("Скасувати тренування?", isPresented: $showCancelAlert) {
            Button("Скасувати", role: .destructive) { dismiss() }
            Button("Продовжити", role: .cancel) { }
        } message: {
            Text("Прогрес буде втрачено")
        }
        .fullScreenCover(isPresented: $showSummary) {
            summarySheet
        }
    }

    func initSets(_ exercise: Exercise) -> [ActiveSetData] {
        let suggested: String? = {
            guard let weight = exercise.suggestedWeightKg, weight > 0 else { return nil }
            // Adjust weight for light workout
            let adjustedWeight = isLightWorkout ? weight * 0.8 : weight
            if adjustedWeight.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", adjustedWeight)
            }
            return String(format: "%.1f", adjustedWeight)
        }()
        // Use adjusted sets count for light workout
        let setsCount = adjustedSetsCount(for: exercise)
        return (0..<setsCount).map { _ in
            ActiveSetData(rir: exercise.rir, suggestedWeight: suggested)
        }
    }

    func initAllSets() {
        for exercise in workoutDay.exercises {
            if setData[exercise.id] == nil {
                setData[exercise.id] = initSets(exercise)
            }
        }
    }

    func startRestTimer(_ seconds: Int) {
        restTimer = seconds
    }

    func finishWorkout() {
        // Calculate total volume
        var totalVolume: Double = 0
        var completedSets: [CompletedSet] = []

        for (exerciseId, sets) in setData {
            let exerciseName = workoutDay.exercises.first(where: { $0.id == exerciseId })?.name ?? ""

            for (i, set) in sets.enumerated() where set.isCompleted {
                let weight = Double(set.weight.replacingOccurrences(of: ",", with: ".")) ?? 0
                let reps = Int(set.reps) ?? 0
                totalVolume += weight * Double(reps)

                let completed = CompletedSet(
                    exerciseId: exerciseId,
                    exerciseName: exerciseName,
                    setNumber: i + 1,
                    weightKg: weight,
                    reps: reps,
                    rir: set.rir,
                    isCompleted: true
                )
                completedSets.append(completed)
            }
        }

        // Create workout log
        let log = WorkoutLog(
            workoutDayId: workoutDay.id,
            workoutDayName: workoutDay.dayName,
            durationMinutes: elapsedSeconds / 60,
            totalVolume: totalVolume,
            completedSets: completedSets
        )

        modelContext.insert(log)
        for set in completedSets {
            modelContext.insert(set)
        }

        try? modelContext.save()
        currentLog = log
        showSummary = true
    }
}

extension ActiveWorkoutView {
    @ViewBuilder
    var summarySheet: some View {
        if let log = currentLog {
            WorkoutSummaryView(workoutLog: log, workoutDay: workoutDay)
                .onDisappear { dismiss() }
        }
    }
}

// MARK: - Timer Bar

struct WorkoutTimerBar: View {
    let elapsed: Int
    let restTimer: Int?

    var body: some View {
        HStack {
            // Total time
            Label(formatTime(elapsed), systemImage: "timer")
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            // Rest timer indicator
            if let rest = restTimer, rest > 0 {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Відпочинок: \(formatTime(rest))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(white: 0.08))
    }

    func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    let exercise: Exercise
    @Binding var sets: [ActiveWorkoutView.ActiveSetData]
    let onSetCompleted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(exercise.sets) підходи · \(exercise.repsMin)-\(exercise.repsMax) повт · RIR \(exercise.rir)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if !exercise.notes.isEmpty {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                }
            }

            // Set rows
            ForEach(sets.indices, id: \.self) { i in
                SetRow(
                    setNumber: i + 1,
                    setData: $sets[i],
                    targetRepsMin: exercise.repsMin,
                    targetRepsMax: exercise.repsMax,
                    onComplete: {
                        onSetCompleted()
                    }
                )
            }

            // Add set button
            Button {
                let suggested: String? = {
                    guard let weight = exercise.suggestedWeightKg, weight > 0 else { return nil }
                    if weight.truncatingRemainder(dividingBy: 1) == 0 {
                        return String(format: "%.0f", weight)
                    }
                    return String(format: "%.1f", weight)
                }()
                sets.append(ActiveWorkoutView.ActiveSetData(rir: exercise.rir, suggestedWeight: suggested))
            } label: {
                Label("Додати підхід", systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }
}

// MARK: - Set Row

enum SetState {
    case ready
    case enterReps
    case completed
}

struct SetRow: View {
    let setNumber: Int
    @Binding var setData: ActiveWorkoutView.ActiveSetData
    let targetRepsMin: Int
    let targetRepsMax: Int
    let onComplete: () -> Void

    @State private var state: SetState = .ready

    var body: some View {
        VStack(spacing: 0) {
            switch state {

            case .ready:
                readyView

            case .enterReps:
                enterRepsView

            case .completed:
                completedView
            }
        }
        .onAppear {
            if setData.isCompleted {
                state = .completed
            }
        }
    }

    // MARK: - Ready State (weight input + START button)
    private var readyView: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.subheadline.bold())
                .foregroundColor(.gray)
                .frame(width: 28)

            HStack(spacing: 4) {
                TextField(
                    setData.suggestedWeight ?? "0",
                    text: $setData.weight
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(width: 72)
                .padding(.vertical, 10)
                .background(Color(white: 0.15))
                .cornerRadius(10)
                Text("кг")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text("\(targetRepsMin)-\(targetRepsMax)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 50)

            Spacer()

            Button {
                state = .enterReps
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text("СТАРТ")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Enter Reps State (big reps input)
    private var enterRepsView: some View {
        VStack(spacing: 16) {
            Text("Підхід \(setNumber) — скільки повторень?")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 32) {
                Button {
                    let current = Int(setData.reps) ?? targetRepsMin
                    setData.reps = "\(max(1, current - 1))"
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(white: 0.3))
                }

                Text(setData.reps.isEmpty ? "\(targetRepsMin)" : setData.reps)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 100)

                Button {
                    let current = Int(setData.reps) ?? targetRepsMin
                    setData.reps = "\(current + 1)"
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(white: 0.3))
                }
            }

            // Quick rep buttons
            HStack(spacing: 10) {
                ForEach(quickRepOptions, id: \.self) { rep in
                    Button("\(rep)") {
                        setData.reps = "\(rep)"
                    }
                    .font(.headline)
                    .foregroundColor(setData.reps == "\(rep)" ? .black : .white)
                    .frame(width: 48, height: 48)
                    .background(setData.reps == "\(rep)" ? Color.white : Color(white: 0.15))
                    .cornerRadius(12)
                }
            }

            // RIR picker
            HStack(spacing: 12) {
                Text("RIR:")
                    .foregroundColor(.gray)
                ForEach(0...4, id: \.self) { rir in
                    Button("\(rir)") {
                        setData.rir = rir
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(setData.rir == rir ? .black : .white)
                    .frame(width: 40, height: 36)
                    .background(setData.rir == rir ? Color.white : Color(white: 0.2))
                    .cornerRadius(10)
                }
            }

            Button {
                if setData.reps.isEmpty { setData.reps = "\(targetRepsMin)" }
                setData.isCompleted = true
                state = .completed
                onComplete()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } label: {
                Text("✓  Записати підхід")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(white: 0.06))
        .cornerRadius(16)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Completed State (compact row)
    private var completedView: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.subheadline.bold())
                .foregroundColor(.gray)
                .frame(width: 28)

            Text("\(setData.weight.isEmpty ? (setData.suggestedWeight ?? "0") : setData.weight) кг")
                .foregroundColor(Color(white: 0.5))
                .frame(width: 72, alignment: .center)

            Text("\(setData.reps) повт")
                .foregroundColor(Color(white: 0.5))
                .frame(width: 70)

            Text("RIR \(setData.rir)")
                .font(.caption)
                .foregroundColor(Color(white: 0.4))

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 22))

            Button {
                setData.isCompleted = false
                state = .ready
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .opacity(0.7)
    }

    private var quickRepOptions: [Int] {
        [targetRepsMin - 1, targetRepsMin, targetRepsMax - 1, targetRepsMax, targetRepsMax + 1].filter { $0 > 0 }
    }
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: View {
    let timeRemaining: Int
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Відпочинок")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text(formatTime(timeRemaining))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Button(action: onSkip) {
                    Text("Пропустити")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    let exercise = Exercise(
        name: "Жим лежачи",
        nameEn: "Bench Press",
        sets: 4,
        repsMin: 6,
        repsMax: 10,
        rir: 2,
        restSeconds: 180,
        notes: "Головна компаунд вправа",
        muscleGroup: "chest",
        exerciseType: "compound"
    )

    let day = WorkoutDay(
        dayName: "Push A",
        focus: "Груди, Дельти, Трицепс",
        exercises: [exercise]
    )

    return ActiveWorkoutView(workoutDay: day)
        .modelContainer(for: [WorkoutLog.self, CompletedSet.self])
}
