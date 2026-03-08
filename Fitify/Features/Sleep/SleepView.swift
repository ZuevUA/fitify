//
//  SleepView.swift
//  Fitify
//

import SwiftUI

struct SleepView: View {
    @Bindable var viewModel: SleepViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Main Sleep Card
                    SleepSummaryCard(
                        totalSleep: viewModel.formattedTotalSleep,
                        qualityScore: viewModel.sleepQualityScore
                    )

                    // Sleep Phases Timeline
                    SleepTimelineCard(timeline: viewModel.sleepTimeline)

                    // Phase Statistics
                    SleepPhasesGrid(
                        deep: viewModel.formattedDeep,
                        rem: viewModel.formattedREM,
                        light: viewModel.formattedLight,
                        awake: viewModel.formattedAwake
                    )

                    // Weekly Chart
                    WeeklySleepChart(
                        hours: viewModel.weeklySleepHours,
                        days: viewModel.weekDays,
                        goal: viewModel.sleepGoalHours
                    )

                    // AI Recommendation
                    SleepRecommendationCard(text: viewModel.aiRecommendation)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.black)
            .navigationTitle("Сон")
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Sleep Summary Card

struct SleepSummaryCard: View {
    let totalSleep: String
    let qualityScore: Int

    private var qualityColor: Color {
        switch qualityScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            // Total Sleep
            VStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.title)
                    .foregroundStyle(.indigo)

                Text(totalSleep)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Тривалість")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 80)

            // Quality Score
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(qualityColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: Double(qualityScore) / 100)
                        .stroke(qualityColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(qualityScore)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text("Якість")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Sleep Timeline

struct SleepTimelineCard: View {
    let timeline: [(time: String, phase: Int)]

    private let phaseColors: [Color] = [
        Color(red: 1.0, green: 0.27, blue: 0.27),  // Awake - red
        Color(red: 0.29, green: 0.62, blue: 1.0),  // Light - blue
        Color(red: 0.0, green: 1.0, blue: 0.53),   // REM - green
        Color(red: 0.36, green: 0.36, blue: 1.0)   // Deep - purple
    ]

    private let phaseNames = ["Пробудження", "Легкий", "REM", "Глибокий"]
    private let phaseHeights: [CGFloat] = [20, 40, 60, 80]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Фази сну")
                .font(.headline)

            // Timeline bars
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(phaseColors[item.phase])
                        .frame(height: phaseHeights[item.phase])
                }
            }
            .frame(height: 80)

            // Time labels
            HStack {
                Text("23:00")
                Spacer()
                Text("01:00")
                Spacer()
                Text("03:00")
                Spacer()
                Text("05:00")
                Spacer()
                Text("07:00")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            // Legend
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(phaseColors[index])
                            .frame(width: 8, height: 8)
                        Text(phaseNames[index])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Sleep Phases Grid

struct SleepPhasesGrid: View {
    let deep: String
    let rem: String
    let light: String
    let awake: String

    var body: some View {
        HStack(spacing: 12) {
            PhaseCard(
                name: "Глибокий",
                value: deep,
                color: Color(red: 0.36, green: 0.36, blue: 1.0)
            )
            PhaseCard(
                name: "REM",
                value: rem,
                color: Color(red: 0.0, green: 1.0, blue: 0.53)
            )
            PhaseCard(
                name: "Легкий",
                value: light,
                color: Color(red: 0.29, green: 0.62, blue: 1.0)
            )
            PhaseCard(
                name: "Пробудж.",
                value: awake,
                color: Color(red: 1.0, green: 0.27, blue: 0.27)
            )
        }
    }
}

struct PhaseCard: View {
    let name: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weekly Sleep Chart

struct WeeklySleepChart: View {
    let hours: [Double]
    let days: [String]
    let goal: Double

    private var maxHours: Double {
        max(hours.max() ?? goal, goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Тиждень")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.indigo.opacity(0.3))
                        .frame(width: 16, height: 2)
                    Text("Ціль \(Int(goal))г")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            ZStack(alignment: .top) {
                // Goal line
                Rectangle()
                    .fill(Color.indigo.opacity(0.3))
                    .frame(height: 2)
                    .offset(y: maxHours > 0 ? CGFloat(1 - goal / maxHours) * 100 : 0)

                // Bars
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(zip(days.indices, days)), id: \.0) { index, day in
                        VStack(spacing: 8) {
                            let barHeight = maxHours > 0
                                ? CGFloat(hours[index] / maxHours) * 100
                                : 0
                            let isAboveGoal = hours[index] >= goal

                            RoundedRectangle(cornerRadius: 4)
                                .fill(isAboveGoal ? Color.indigo : Color.indigo.opacity(0.5))
                                .frame(width: 28, height: barHeight)

                            Text(String(format: "%.1f", hours[index]))
                                .font(.caption2)
                                .foregroundStyle(.white)

                            Text(day)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - AI Recommendation Card

struct SleepRecommendationCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.indigo)

                Text("Рекомендація AI")
                    .font(.headline)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    SleepView(viewModel: SleepViewModel())
}
