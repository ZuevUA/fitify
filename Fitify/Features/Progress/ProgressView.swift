//
//  ProgressView.swift
//  Fitify
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Main Progress View

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProgressViewModel()
    @State private var selectedTab = 0

    let tabs = ["Сила", "Тіло", "Об'єм", "Здоров'я"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tabs.indices, id: \.self) { i in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTab = i
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: tabIcon(for: i))
                                            .font(.caption)
                                        Text(tabs[i])
                                    }
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == i ? Color.white : Color(white: 0.12))
                                    .foregroundColor(selectedTab == i ? .black : .white)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)

                    // Time Range Picker
                    Picker("Період", selection: $viewModel.timeRange) {
                        ForEach(ProgressViewModel.TimeRange.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                StrengthProgressView(viewModel: viewModel)
                                OneRMCalculatorView(viewModel: viewModel)
                            case 1:
                                BodyCompositionView()
                            case 2:
                                VolumeLoadView(viewModel: viewModel)
                            case 3:
                                HRVTrendView(viewModel: viewModel)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Прогрес")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { viewModel.loadData(from: modelContext) }
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "dumbbell.fill"
        case 1: return "scalemass.fill"
        case 2: return "chart.bar.fill"
        case 3: return "heart.fill"
        default: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Strength Progress View

struct StrengthProgressView: View {
    let viewModel: ProgressViewModel

    @State private var selectedExercise: String?
    @State private var showOneRM = false

    var chartData: [StrengthDataPoint] {
        guard let exercise = selectedExercise else { return [] }
        return viewModel.strengthData(for: exercise)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Силовий прогрес")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Toggle("1RM", isOn: $showOneRM)
                    .toggleStyle(.button)
                    .tint(.blue)
                    .font(.caption)
            }

            // Exercise selector
            let exercises = viewModel.exercisesWithData()
            if exercises.isEmpty {
                EmptyChartPlaceholder(
                    icon: "dumbbell",
                    message: "Потрібно завершити хоча б одне тренування"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exercises, id: \.self) { exercise in
                            Button(exercise) {
                                selectedExercise = exercise
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedExercise == exercise
                                ? Color.blue : Color(white: 0.15)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                }
                .onAppear {
                    if selectedExercise == nil {
                        selectedExercise = exercises.first
                    }
                }

                if chartData.isEmpty {
                    EmptyChartPlaceholder(
                        icon: "dumbbell",
                        message: "Немає даних для цієї вправи"
                    )
                } else {
                    // Statistics
                    if let latest = chartData.last, let first = chartData.first {
                        let currentVal = showOneRM ? latest.estimatedOneRM : latest.maxWeight
                        let firstVal = showOneRM ? first.estimatedOneRM : first.maxWeight
                        let diff = currentVal - firstVal

                        HStack(spacing: 12) {
                            StatPill(
                                label: showOneRM ? "Розр. 1RM" : "Макс. вага",
                                value: String(format: "%.1f кг", currentVal),
                                color: .blue
                            )
                            StatPill(
                                label: "Прогрес",
                                value: String(format: "%+.1f кг", diff),
                                color: diff >= 0 ? .green : .red
                            )
                            StatPill(
                                label: "Тренувань",
                                value: "\(chartData.count)",
                                color: .gray
                            )
                        }
                    }

                    // Chart
                    Chart {
                        ForEach(chartData) { point in
                            let yValue = showOneRM ? point.estimatedOneRM : point.maxWeight

                            // Line
                            LineMark(
                                x: .value("Дата", point.date),
                                y: .value("Вага", yValue)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)

                            // Points
                            PointMark(
                                x: .value("Дата", point.date),
                                y: .value("Вага", yValue)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(40)

                            // Area under line
                            AreaMark(
                                x: .value("Дата", point.date),
                                y: .value("Вага", yValue)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        // PR annotation
                        if let maxPoint = chartData.max(by: {
                            (showOneRM ? $0.estimatedOneRM : $0.maxWeight) <
                            (showOneRM ? $1.estimatedOneRM : $1.maxWeight)
                        }) {
                            let yVal = showOneRM ? maxPoint.estimatedOneRM : maxPoint.maxWeight
                            RuleMark(y: .value("Рекорд", yVal))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(Color.yellow.opacity(0.6))
                                .annotation(position: .trailing) {
                                    Text("PR")
                                        .font(.caption2.bold())
                                        .foregroundColor(.yellow)
                                }
                        }
                    }
                    .frame(height: 220)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                .foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                .foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))кг")
                                        .font(.caption)
                                        .foregroundStyle(Color.gray)
                                }
                            }
                        }
                    }
                    .chartBackground { _ in Color.clear }
                }
            }
        }
        .padding()
        .background(Color(white: 0.07))
        .cornerRadius(20)
    }
}

// MARK: - Body Composition View

struct BodyCompositionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightLog.date) private var weightLogs: [BodyWeightLog]

    @State private var showAddWeight = false

    var trendLine: [BodyWeightEntry] {
        // 7-day moving average
        guard weightLogs.count >= 7 else { return [] }
        return weightLogs.enumerated().compactMap { i, log in
            guard i >= 6 else { return nil }
            let window = Array(weightLogs[(i-6)...i])
            let avg = window.map { $0.weightKg }.reduce(0, +) / 7.0
            return BodyWeightEntry(date: log.date, weightKg: avg)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Склад тіла")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showAddWeight = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }

            if weightLogs.isEmpty {
                EmptyChartPlaceholder(
                    icon: "scalemass",
                    message: "Внеси першу вагу щоб почати відстеження"
                )
                Button("+ Додати вагу") { showAddWeight = true }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(14)
            } else {
                // Statistics
                if let first = weightLogs.first, let last = weightLogs.last {
                    let diff = last.weightKg - first.weightKg
                    HStack(spacing: 12) {
                        StatPill(label: "Зараз", value: "\(String(format: "%.1f", last.weightKg)) кг", color: .white)
                        StatPill(label: "Зміна", value: String(format: "%+.1f кг", diff), color: diff < 0 ? .green : .orange)
                        StatPill(label: "Записів", value: "\(weightLogs.count)", color: .gray)
                    }
                }

                // Chart
                Chart {
                    // Daily points (semi-transparent)
                    ForEach(weightLogs, id: \.date) { log in
                        PointMark(
                            x: .value("Дата", log.date),
                            y: .value("Вага", log.weightKg)
                        )
                        .foregroundStyle(Color.green.opacity(0.4))
                        .symbolSize(20)
                    }

                    // Moving average (bright line)
                    ForEach(trendLine) { point in
                        LineMark(
                            x: .value("Дата", point.date),
                            y: .value("Тренд", point.weightKg)
                        )
                        .foregroundStyle(Color.green)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))кг").font(.caption).foregroundStyle(Color.gray)
                            }
                        }
                    }
                }

                Text("Яскрава лінія — 7-денна середня (фільтрує коливання)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(white: 0.07))
        .cornerRadius(20)
        .sheet(isPresented: $showAddWeight) {
            AddWeightSheet { weight, date in
                let log = BodyWeightLog(weightKg: weight, date: date)
                modelContext.insert(log)
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Add Weight Sheet

struct AddWeightSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Double, Date) -> Void
    @State private var weight = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Large weight input
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("70.0", text: $weight)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 180)
                        Text("кг")
                            .font(.title)
                            .foregroundColor(.gray)
                    }

                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Додати вагу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }.foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        if let w = Double(weight.replacingOccurrences(of: ",", with: ".")) {
                            onSave(w, date)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(weight.isEmpty ? .gray : .white)
                    .disabled(weight.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Volume Load View

struct VolumeLoadView: View {
    let viewModel: ProgressViewModel
    @State private var groupBy: GroupBy = .week

    enum GroupBy: String, CaseIterable {
        case week = "Тиждень"
        case month = "Місяць"
    }

    var data: [VolumeDataPoint] { viewModel.weeklyVolumeData() }
    var maxTonnage: Double { data.map { $0.tonnage }.max() ?? 1 }
    var avgTonnage: Double {
        guard !data.isEmpty else { return 0 }
        return data.reduce(0.0) { $0 + $1.tonnage } / Double(data.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Об'єм тренувань")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Picker("", selection: $groupBy) {
                    ForEach(GroupBy.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if data.isEmpty {
                EmptyChartPlaceholder(icon: "chart.bar", message: "Немає даних тренувань")
            } else {
                // Total statistics
                let total = data.reduce(0.0) { $0 + $1.tonnage }
                HStack(spacing: 12) {
                    StatPill(label: "Всього", value: String(format: "%.1f т", total), color: .orange)
                    StatPill(label: "Середнє/тиждень", value: String(format: "%.2f т", avgTonnage), color: .gray)
                    StatPill(label: "Тижнів", value: "\(data.count)", color: .gray)
                }

                // Bar Chart
                Chart(data) { point in
                    BarMark(
                        x: .value("Тиждень", point.weekStart, unit: .weekOfYear),
                        y: .value("Тонни", point.tonnage)
                    )
                    .foregroundStyle(
                        point.tonnage == maxTonnage
                        ? Color.orange.gradient
                        : Color.orange.opacity(0.6).gradient
                    )
                    .cornerRadius(4)

                    // Average line
                    RuleMark(y: .value("Середнє", avgTonnage))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .annotation(position: .leading) {
                            Text("avg")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(String(format: "%.1f", v))т")
                                    .font(.caption).foregroundStyle(Color.gray)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.07))
        .cornerRadius(20)
    }
}

// MARK: - HRV Trend View

struct HRVTrendView: View {
    let viewModel: ProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HRV Тренд")
                .font(.title2.bold())
                .foregroundColor(.white)

            // Placeholder - needs HealthKit integration
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 48))
                    .foregroundColor(.purple.opacity(0.6))

                Text("HRV дані з Apple Watch")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Графік HRV буде доступний після синхронізації даних з HealthKit")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // Legend
                HStack(spacing: 16) {
                    LegendDot(color: .purple, label: "HRV (мс)")
                    LegendDot(color: .blue.opacity(0.5), label: "Норма")
                    LegendDot(color: .orange, label: "Тренування")
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
        }
        .padding()
        .background(Color(white: 0.07))
        .cornerRadius(20)
    }
}

// MARK: - 1RM Calculator View

struct OneRMCalculatorView: View {
    let viewModel: ProgressViewModel
    @State private var manualWeight = ""
    @State private var manualReps = 5

    var topResults: [OneRMResult] {
        viewModel.topOneRMResults()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Розрахунок 1RM")
                .font(.title2.bold())
                .foregroundColor(.white)

            // Manual calculator
            VStack(spacing: 12) {
                Text("Швидкий розрахунок")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Вага (кг)").font(.caption).foregroundColor(.gray)
                        TextField("100", text: $manualWeight)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .padding(10)
                            .background(Color(white: 0.12))
                            .cornerRadius(10)
                            .frame(width: 100)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Повторень").font(.caption).foregroundColor(.gray)
                        HStack {
                            Button { manualReps = max(1, manualReps - 1) } label: {
                                Image(systemName: "minus").foregroundColor(.white)
                            }
                            Text("\(manualReps)")
                                .font(.title2.bold()).foregroundColor(.white)
                                .frame(width: 40)
                            Button { manualReps = min(20, manualReps + 1) } label: {
                                Image(systemName: "plus").foregroundColor(.white)
                            }
                        }
                        .padding(10)
                        .background(Color(white: 0.12))
                        .cornerRadius(10)
                    }

                    if let w = Double(manualWeight.replacingOccurrences(of: ",", with: ".")),
                       manualReps > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1RM").font(.caption).foregroundColor(.gray)
                            Text("\(String(format: "%.1f", viewModel.calculateOneRM(weight: w, reps: manualReps))) кг")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                        }
                    }
                }

                // Percentage table
                if let w = Double(manualWeight.replacingOccurrences(of: ",", with: ".")) {
                    let oneRM = viewModel.calculateOneRM(weight: w, reps: manualReps)
                    VStack(spacing: 4) {
                        Text("Відсотки від 1RM").font(.caption.bold()).foregroundColor(.gray)
                        HStack(spacing: 0) {
                            ForEach([100, 95, 90, 85, 80, 75, 70], id: \.self) { pct in
                                VStack(spacing: 2) {
                                    Text("\(pct)%")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("\(Int(oneRM * Double(pct) / 100))")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(pct == 100 ? Color.green.opacity(0.2) : Color(white: 0.1))
                            }
                        }
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(14)

            // Automatic 1RM from workouts
            if !topResults.isEmpty {
                Text("Рекорди з тренувань")
                    .font(.subheadline.bold())
                    .foregroundColor(.gray)

                ForEach(topResults.prefix(8)) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.exerciseName)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text("\(String(format: "%.1f", result.bestSetWeight))кг × \(result.bestSetReps) повт")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.1f", result.estimatedOneRM)) кг")
                                .font(.headline.bold())
                                .foregroundColor(.green)
                            Text("~1RM")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    Divider().background(Color(white: 0.15))
                }
            }
        }
        .padding()
        .background(Color(white: 0.07))
        .cornerRadius(20)
    }
}

// MARK: - Shared Components

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
}

struct EmptyChartPlaceholder: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundColor(.gray)
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressView()
        .modelContainer(for: [WorkoutLog.self, BodyWeightLog.self])
}
