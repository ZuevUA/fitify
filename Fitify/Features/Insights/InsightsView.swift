//
//  InsightsView.swift
//  Fitify
//

import SwiftUI

struct InsightsView: View {
    @Bindable var viewModel: InsightsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                FilterTabsView(selectedFilter: $viewModel.selectedFilter)

                ScrollView {
                    LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                        // Anomaly Summary Section (if available)
                        if let anomalyResult = viewModel.anomalyResult, viewModel.hasImportantAnomalies {
                            Section {
                                AnomalySummarySection(result: anomalyResult)
                            } header: {
                                DateHeaderView(date: "Важливо")
                            }
                        }

                        // Detection in progress indicator
                        if viewModel.isDetectingAnomalies {
                            HStack {
                                ProgressView()
                                    .tint(.blue)
                                Text("Аналізую тренди здоров'я...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                        }

                        // Regular insights
                        if viewModel.filteredInsights.isEmpty {
                            EmptyInsightsView()
                        } else {
                            ForEach(viewModel.groupedInsights, id: \.date) { group in
                                Section {
                                    ForEach(group.insights, id: \.id) { insight in
                                        InsightRowView(insight: insight) {
                                            viewModel.markAsRead(insight)
                                        }
                                    }
                                } header: {
                                    DateHeaderView(date: group.date)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.black)
            .navigationTitle("Інсайти")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isGenerating {
                        ProgressView()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            viewModel.loadInsights()
            await viewModel.syncHistoryIfNeeded()
            await viewModel.runAnomalyDetectionIfNeeded()
        }
        .refreshable {
            await viewModel.runAnomalyDetection()
        }
    }
}

// MARK: - Filter Tabs

struct FilterTabsView: View {
    @Binding var selectedFilter: InsightFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.black)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.cardBackground)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Date Header

struct DateHeaderView: View {
    let date: String

    var body: some View {
        HStack {
            Text(date)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.black)
    }
}

// MARK: - Empty State

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text("Поки що інсайтів немає")
                    .font(.title3.weight(.semibold))

                Text("AI аналізує твої дані здоров'я...\nПерші інсайти з'являться незабаром")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Loading indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Insight Row

struct InsightRowView: View {
    let insight: AIInsight
    let onTap: () -> Void

    private var categoryColor: Color {
        switch insight.insightCategory {
        case .recovery: return .green
        case .sleep: return .indigo
        case .activity: return .orange
        case .stress: return .purple
        case .illness: return .red
        case .general: return .blue
        }
    }

    private var badgeStyle: BadgeStyle {
        switch insight.priority {
        case 1: return .alert
        case 2: return .warning
        default: return .info
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: insight.insightCategory.iconName)
                            .font(.body)
                            .foregroundStyle(categoryColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Spacer()

                            // Badge
                            InsightBadge(style: badgeStyle)
                        }

                        Text(insight.insightCategory.displayName)
                            .font(.caption)
                            .foregroundStyle(categoryColor)
                    }
                }

                Text(insight.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Footer
                HStack {
                    // Unread indicator
                    if !insight.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                        Text("Нове")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    Text(formatTime(insight.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM, HH:mm"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Badge

enum BadgeStyle {
    case info, warning, alert
}

struct InsightBadge: View {
    let style: BadgeStyle

    private var color: Color {
        switch style {
        case .info: return .blue
        case .warning: return .orange
        case .alert: return .red
        }
    }

    private var text: String {
        switch style {
        case .info: return "info"
        case .warning: return "!"
        case .alert: return "!!"
        }
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    InsightsView(viewModel: InsightsViewModel())
}
