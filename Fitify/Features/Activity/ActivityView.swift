//
//  ActivityView.swift
//  Fitify
//

import SwiftUI

struct ActivityView: View {
    @Bindable var viewModel: ActivityViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Activity Rings
                    ActivityRingsCard(
                        moveProgress: viewModel.moveProgress,
                        exerciseProgress: viewModel.exerciseProgress,
                        standProgress: viewModel.standProgress,
                        calories: viewModel.formattedCalories,
                        exercise: viewModel.formattedExercise,
                        stand: viewModel.formattedStand,
                        caloriesGoal: viewModel.caloriesGoal,
                        exerciseGoal: viewModel.exerciseGoal,
                        standGoal: viewModel.standGoal
                    )

                    // Steps Card
                    StepsCard(
                        steps: viewModel.formattedSteps,
                        goal: viewModel.stepsGoal,
                        remaining: viewModel.formattedStepsRemaining,
                        progress: viewModel.stepsProgress
                    )

                    // Weekly Activity
                    WeeklyActivityChart(
                        steps: viewModel.weeklySteps,
                        days: viewModel.weekDays,
                        goal: viewModel.stepsGoal
                    )

                    // Recent Workouts
                    RecentWorkoutsCard(workouts: viewModel.recentWorkouts)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.black)
            .navigationTitle("Активність")
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Activity Rings Card

struct ActivityRingsCard: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double
    let calories: String
    let exercise: String
    let stand: String
    let caloriesGoal: Int
    let exerciseGoal: Int
    let standGoal: Int

    private let moveColor = Color(red: 1.0, green: 0.27, blue: 0.27)
    private let exerciseColor = Color(red: 0.0, green: 1.0, blue: 0.53)
    private let standColor = Color(red: 0.29, green: 0.62, blue: 1.0)

    var body: some View {
        VStack(spacing: 20) {
            // Rings
            ZStack {
                // Move ring (outer)
                ActivityRingShape(progress: moveProgress, lineWidth: 20)
                    .stroke(moveColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)

                // Exercise ring (middle)
                ActivityRingShape(progress: exerciseProgress, lineWidth: 20)
                    .stroke(exerciseColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 115, height: 115)

                // Stand ring (inner)
                ActivityRingShape(progress: standProgress, lineWidth: 20)
                    .stroke(standColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 70, height: 70)

                // Background rings
                Circle()
                    .stroke(moveColor.opacity(0.2), lineWidth: 20)
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(exerciseColor.opacity(0.2), lineWidth: 20)
                    .frame(width: 115, height: 115)

                Circle()
                    .stroke(standColor.opacity(0.2), lineWidth: 20)
                    .frame(width: 70, height: 70)
            }
            .padding(.vertical, 8)

            // Stats
            HStack(spacing: 24) {
                RingStatItem(
                    color: moveColor,
                    title: "Рух",
                    value: calories,
                    unit: "ккал",
                    goal: caloriesGoal
                )

                RingStatItem(
                    color: exerciseColor,
                    title: "Вправи",
                    value: exercise,
                    unit: "хв",
                    goal: exerciseGoal
                )

                RingStatItem(
                    color: standColor,
                    title: "На ногах",
                    value: stand,
                    unit: "год",
                    goal: standGoal
                )
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct ActivityRingShape: Shape {
    var progress: Double
    var lineWidth: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: (min(rect.width, rect.height) - lineWidth) / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )
        return path
    }
}

struct RingStatItem: View {
    let color: Color
    let title: String
    let value: String
    let unit: String
    let goal: Int

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("/\(goal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Steps Card

struct StepsCard: View {
    let steps: String
    let goal: Int
    let remaining: String
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Кроки")
                    .font(.headline)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(steps)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("з \(goal.formatted()) цілі")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(remaining)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.green.opacity(0.8))

                    Text("залишилось")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Weekly Activity Chart

struct WeeklyActivityChart: View {
    let steps: [Int]
    let days: [String]
    let goal: Int

    private var maxSteps: Int {
        max(steps.max() ?? goal, goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Тижнева активність")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 16, height: 2)
                    Text("Ціль")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            ZStack(alignment: .top) {
                // Goal line
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(height: 2)
                    .offset(y: maxSteps > 0 ? CGFloat(1 - Double(goal) / Double(maxSteps)) * 80 : 0)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(zip(days.indices, days)), id: \.0) { index, day in
                        VStack(spacing: 8) {
                            let height = maxSteps > 0
                                ? CGFloat(steps[index]) / CGFloat(maxSteps) * 80
                                : 0
                            let isAboveGoal = steps[index] >= goal

                            RoundedRectangle(cornerRadius: 4)
                                .fill(isAboveGoal ? Color.green : Color.green.opacity(0.5))
                                .frame(width: 28, height: max(height, 4))

                            Text(day)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Recent Workouts Card

struct RecentWorkoutsCard: View {
    let workouts: [Workout]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Останні тренування")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(workouts) { workout in
                    HStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: workout.iconName)
                                .font(.title3)
                                .foregroundStyle(.orange)
                        }

                        // Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                Text(workout.formattedDuration)
                                Text("•")
                                Text(workout.formattedCalories)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Time ago
                        Text(workout.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if workout.id != workouts.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ActivityView(viewModel: ActivityViewModel())
}
