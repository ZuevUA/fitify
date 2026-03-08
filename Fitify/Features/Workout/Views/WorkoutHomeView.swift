//
//  WorkoutHomeView.swift
//  Fitify
//

import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutProgram> { $0.isActive })
    private var activePrograms: [WorkoutProgram]

    @Query(sort: \WorkoutLog.date, order: .reverse)
    private var recentLogs: [WorkoutLog]

    @State private var selectedWorkoutDay: WorkoutDay?
    @State private var showingActiveWorkout = false

    private var activeProgram: WorkoutProgram? {
        activePrograms.first
    }

    private var todaysWorkout: WorkoutDay? {
        guard let program = activeProgram else { return nil }
        guard !program.weeklySchedule.isEmpty else { return program.workoutDays.first }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Map to index (0-6)
        let index = (weekday + 5) % 7
        // FIX: перевірка що index в межах
        guard index >= 0 && index < program.weeklySchedule.count else {
            return program.workoutDays.first
        }
        let dayName = program.weeklySchedule[index]
        return program.workoutDays.first { $0.dayName == dayName }
    }

    private var completedThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return recentLogs.filter { $0.date >= startOfWeek }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Workout Card
                    TodayWorkoutCard(
                        workoutDay: todaysWorkout,
                        onStart: {
                            if let day = todaysWorkout {
                                selectedWorkoutDay = day
                                showingActiveWorkout = true
                            }
                        }
                    )

                    // Weekly Progress
                    WeeklyProgressCard(
                        completed: completedThisWeek,
                        total: activeProgram?.workoutDays.count ?? 4
                    )

                    // Recent Workouts
                    if !recentLogs.isEmpty {
                        RecentWorkoutsSection(logs: Array(recentLogs.prefix(3)))
                    }

                    // AI Recommendation Button
                    AIRecommendationButton()

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.black)
            .navigationTitle("Тренування")
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let day = selectedWorkoutDay {
                ActiveWorkoutView(workoutDay: day)
            }
        }
    }

    private var trainingDaysPerWeek: Int {
        activeProgram?.workoutDays.count ?? 4
    }
}

// MARK: - Today's Workout Card

struct TodayWorkoutCard: View {
    let workoutDay: WorkoutDay?
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сьогодні")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let day = workoutDay {
                        Text(day.dayName)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        Text(day.focus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("День відпочинку")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        Text("Відновлюйся та готуйся до наступного тренування")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let day = workoutDay {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(day.exercises.count)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("вправ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if workoutDay != nil {
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Почати тренування")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: workoutDay != nil
                    ? [Color(hex: "1A3A2F"), Color(hex: "0D1F18")]
                    : [Color(hex: "1C1C1E"), Color(hex: "0D0D0D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Weekly Progress Card

struct WeeklyProgressCard: View {
    let completed: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Цього тижня")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(completed)/\(total)")
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? Color.green : Color(hex: "1C1C1E"))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if index < completed {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.black)
                            }
                        }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Recent Workouts Section

struct RecentWorkoutsSection: View {
    let logs: [WorkoutLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Останні тренування")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(logs) { log in
                RecentWorkoutRow(log: log)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct RecentWorkoutRow: View {
    let log: WorkoutLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.workoutDayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(log.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(log.formattedVolume)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)

                Text(log.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - AI Recommendation Button

struct AIRecommendationButton: View {
    var body: some View {
        Button {
            // TODO: Show AI recommendation
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Рекомендація")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Отримай поради для наступного тренування")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    WorkoutHomeView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutLog.self])
}
