//
//  DashboardView.swift
//  Fitify
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @Query private var profiles: [UserProfile]
    @State private var animateProgress = false
    @State private var showProfile = false

    private var profile: UserProfile? { profiles.first }

    private var profileInitials: String {
        guard let name = profile?.name, !name.isEmpty else { return "Я" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(1)).uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Recovery Score
                    RecoveryScoreCard(
                        score: viewModel.recoveryScore,
                        recommendation: viewModel.recoveryRecommendation,
                        animate: animateProgress
                    )

                    // Metrics Grid
                    MetricsGridView(viewModel: viewModel)

                    // Virus Risk Banner
                    if viewModel.virusRisk != .low {
                        VirusRiskBanner(riskLevel: viewModel.virusRisk)
                    }

                    // Weekly Trend
                    WeeklyTrendCard(
                        scores: viewModel.weeklyRecoveryScores,
                        days: viewModel.weekDays
                    )

                    // Latest AI Insight
                    if let insight = viewModel.latestInsight {
                        AIInsightCard(insight: insight)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.greeting)
                            .font(.title2.weight(.bold))
                        Text(viewModel.currentDateFormatted)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Button {
                                Task {
                                    await viewModel.refresh()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.body.weight(.medium))
                            }
                        }

                        // Profile Avatar
                        Button {
                            showProfile = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 32, height: 32)
                                Text(profileInitials)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadData()
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Recovery Score Card

struct RecoveryScoreCard: View {
    let score: Int
    let recommendation: String
    let animate: Bool

    private var progress: Double {
        animate ? Double(score) / 100.0 : 0
    }

    private var gradientColors: [Color] {
        switch score {
        case 80...100:
            return [Color(red: 0.1, green: 0.4, blue: 0.2), Color(red: 0.15, green: 0.5, blue: 0.25)]
        case 50..<80:
            return [Color(red: 0.5, green: 0.4, blue: 0.1), Color(red: 0.6, green: 0.5, blue: 0.15)]
        default:
            return [Color(red: 0.5, green: 0.15, blue: 0.15), Color(red: 0.6, green: 0.2, blue: 0.2)]
        }
    }

    private var scoreColor: Color {
        Color.recoveryColor(for: score)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Recovery Score")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 16)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.2), value: progress)

                // Score text
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("зі 100")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 160, height: 160)

            // Recommendation
            Text(recommendation)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Metrics Grid

struct MetricsGridView: View {
    let viewModel: DashboardViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(
                icon: "heart.fill",
                iconColor: .red,
                title: "Пульс",
                value: viewModel.formattedHeartRate,
                unit: "уд/хв",
                trend: viewModel.heartRateTrend,
                trendUnit: "уд/хв",
                isNormal: viewModel.isMetricNormal(.heartRate)
            )

            MetricCard(
                icon: "waveform.path.ecg",
                iconColor: .purple,
                title: "HRV",
                value: viewModel.formattedHRV,
                unit: "мс",
                trend: viewModel.hrvTrend,
                trendUnit: "мс",
                isNormal: viewModel.isMetricNormal(.hrv),
                invertTrend: true
            )

            MetricCard(
                icon: "bed.double.fill",
                iconColor: .indigo,
                title: "Сон",
                value: viewModel.formattedSleep,
                unit: "",
                trend: viewModel.sleepTrend,
                trendUnit: "хв",
                isNormal: viewModel.isMetricNormal(.sleep),
                invertTrend: true
            )

            MetricCard(
                icon: "brain.head.profile",
                iconColor: .orange,
                title: "Стрес",
                value: viewModel.formattedStress,
                unit: "%",
                trend: viewModel.stressTrend,
                trendUnit: "%",
                isNormal: viewModel.isMetricNormal(.stress)
            )
        }
    }
}

struct MetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let trend: Int
    let trendUnit: String
    let isNormal: Bool
    var invertTrend: Bool = false

    private var trendColor: Color {
        let isPositive = invertTrend ? trend > 0 : trend < 0
        return isPositive ? .green : (trend == 0 ? .gray : .red)
    }

    private var trendArrow: String {
        trend > 0 ? "↑" : (trend < 0 ? "↓" : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)

                Spacer()

                // Status dot
                Circle()
                    .fill(isNormal ? Color.green : Color.yellow)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Trend
                if trend != 0 {
                    HStack(spacing: 2) {
                        Text("\(trendArrow)\(abs(trend)) \(trendUnit)")
                            .font(.caption2)
                            .foregroundStyle(trendColor)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Virus Risk Banner

struct VirusRiskBanner: View {
    let riskLevel: RiskLevel

    private var backgroundColor: Color {
        riskLevel == .high ? .red.opacity(0.15) : .orange.opacity(0.15)
    }

    private var iconColor: Color {
        riskLevel == .high ? .red : .orange
    }

    private var title: String {
        riskLevel == .high ? "Високий ризик хвороби" : "Підвищений ризик хвороби"
    }

    private var message: String {
        riskLevel == .high
            ? "Твої показники вказують на можливу інфекцію. Рекомендовано відпочинок та моніторинг симптомів."
            : "Деякі показники поза нормою. Звертай увагу на самопочуття."
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(iconColor)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Weekly Trend Card

struct WeeklyTrendCard: View {
    let scores: [Int]
    let days: [String]

    private var maxScore: Int {
        scores.max() ?? 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Тижневий тренд")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(zip(days.indices, days)), id: \.0) { index, day in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.recoveryColor(for: scores[index]))
                            .frame(width: 32, height: CGFloat(scores[index]) / 100.0 * 60)

                        // Score label
                        Text("\(scores[index])")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)

                        // Day label
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - AI Insight Card

struct AIInsightCard: View {
    let insight: AIInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.blue)

                Text("Інсайт від AI")
                    .font(.headline)

                Spacer()

                Text(insight.timestamp.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(insight.title)
                .font(.subheadline.weight(.semibold))

            Text(insight.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Spacer()
                Text("Детальніше →")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Preview

#Preview {
    DashboardView(viewModel: DashboardViewModel())
}
