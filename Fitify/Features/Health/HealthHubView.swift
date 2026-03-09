//
//  HealthHubView.swift
//  Fitify
//

import SwiftUI

struct HealthHubView: View {
    @Environment(AppDataCoordinator.self) private var coordinator
    @State private var selectedSegment = 0

    let segments = ["Активність", "Сон", "Інсайти"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented control at top
                    Picker("", selection: $selectedSegment) {
                        ForEach(segments.indices, id: \.self) { i in
                            Text(segments[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Content
                    TabView(selection: $selectedSegment) {
                        ActivityContentView(viewModel: coordinator.activity)
                            .tag(0)

                        SleepContentView(viewModel: coordinator.sleep)
                            .tag(1)

                        InsightsContentView(viewModel: coordinator.insights)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: selectedSegment)
                }
            }
            .navigationTitle("Здоров'я")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Activity Content (without NavigationStack)

struct ActivityContentView: View {
    var viewModel: ActivityViewModel
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Error banner
                if let error = viewModel.errorMessage, showError {
                    ErrorBanner(
                        message: error,
                        retryAction: { Task { await viewModel.loadData() } },
                        isVisible: $showError
                    )
                }

                // Loading skeleton or content
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    HealthHubSkeletonView()
                } else {
                    // Today's Stats
                    HStack(spacing: 12) {
                        ActivityStatCard(
                            icon: "figure.walk",
                            iconColor: .green,
                            value: "\(viewModel.steps)",
                            label: "Кроки",
                            progress: viewModel.stepsProgress
                        )

                        ActivityStatCard(
                            icon: "flame.fill",
                            iconColor: .orange,
                            value: "\(viewModel.calories)",
                            label: "Калорії",
                            progress: viewModel.moveProgress
                        )
                    }

                    HStack(spacing: 12) {
                        ActivityStatCard(
                            icon: "figure.run",
                        iconColor: .blue,
                        value: "\(viewModel.exerciseMinutes)",
                        label: "Хвилин активності",
                        progress: viewModel.exerciseProgress
                    )

                    ActivityStatCard(
                        icon: "arrow.up.heart.fill",
                        iconColor: .red,
                        value: "\(viewModel.standHours)",
                        label: "Години стоячи",
                        progress: viewModel.standProgress
                    )
                }

                // Weekly Activity Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Активність за тиждень")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.weeklySteps.indices, id: \.self) { index in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green.opacity(0.8))
                                    .frame(width: 32, height: max(4, CGFloat(viewModel.weeklySteps[index]) / 10000 * 100))

                                Text(viewModel.weekDays[index])
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                }
                .padding()
                .background(Color(white: 0.08))
                .cornerRadius(16)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .task {
            await viewModel.loadData()
            if viewModel.errorMessage != nil {
                showError = true
            }
        }
    }
}

struct ActivityStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(iconColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }
}

// MARK: - Sleep Content (without NavigationStack)

struct SleepContentView: View {
    var viewModel: SleepViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sleep Score
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 12)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: Double(viewModel.sleepQualityScore) / 100.0)
                            .stroke(
                                Color.indigo,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(viewModel.sleepQualityScore)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Якість сну")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(viewModel.formattedTotalSleep)
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text(viewModel.aiRecommendation)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)

                // Sleep Stages
                VStack(alignment: .leading, spacing: 12) {
                    Text("Фази сну")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        SleepStageCard(
                            stage: "Глибокий",
                            duration: viewModel.formattedDeep,
                            color: .indigo
                        )
                        SleepStageCard(
                            stage: "REM",
                            duration: viewModel.formattedREM,
                            color: .purple
                        )
                        SleepStageCard(
                            stage: "Легкий",
                            duration: viewModel.formattedLight,
                            color: .blue.opacity(0.6)
                        )
                    }
                }
                .padding()
                .background(Color(white: 0.08))
                .cornerRadius(16)

                // Weekly Sleep
                VStack(alignment: .leading, spacing: 12) {
                    Text("Сон за тиждень")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.weeklySleepHours.indices, id: \.self) { index in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.indigo.opacity(0.8))
                                    .frame(width: 32, height: max(4, CGFloat(viewModel.weeklySleepHours[index]) / 10 * 80))

                                Text(viewModel.weekDays[index])
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                }
                .padding()
                .background(Color(white: 0.08))
                .cornerRadius(16)

                Spacer(minLength: 100)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .task {
            await viewModel.loadData()
        }
    }
}

struct SleepStageCard: View {
    let stage: String
    let duration: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(duration)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            Text(stage)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(white: 0.06))
        .cornerRadius(12)
    }
}

// MARK: - Insights Content (without NavigationStack)

struct InsightsContentView: View {
    var viewModel: InsightsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.allInsights.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("Немає інсайтів")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("AI проаналізує твої дані здоров'я та надасть персональні рекомендації")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 250)
                    .padding()
                } else {
                    ForEach(viewModel.allInsights) { insight in
                        InsightCardView(insight: insight)
                    }
                }

                // Anomaly section
                if let anomalyResult = viewModel.anomalyResult {
                    AnomalySummarySection(result: anomalyResult)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .onAppear {
            viewModel.loadInsights()
        }
    }
}

struct InsightCardView: View {
    let insight: AIInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(insight.timestamp.relativeDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(insight.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(4)
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    HealthHubView()
        .environment(AppDataCoordinator())
}
