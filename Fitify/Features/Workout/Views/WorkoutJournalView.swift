//
//  WorkoutJournalView.swift
//  Fitify
//
//  Main workout journal view - Lift App style
//

import SwiftUI
import SwiftData

struct WorkoutJournalView: View {
    @Query private var programs: [WorkoutProgram]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    @State private var showProgramPicker = false
    @State private var showDatePicker = false
    @State private var showEditor = false
    @State private var showDeleteConfirm = false
    @State private var weeklyReport: WeeklyReport?
    @State private var isLoadingReport = false
    @State private var selectedDate: Date = Date()
    @State private var dailyReadiness: DailyReadiness?
    @State private var isLoadingReadiness = false

    // AI Workout Adjustment
    @State private var morningBriefing: MorningBriefing?
    @State private var isLoadingBriefing = false
    @State private var adjustedWorkoutType: String? = nil  // "light" | "rest" | "cardio"
    @State private var dismissedAIBanner = false
    @State private var showRestDayView = false
    @State private var showCardioView = false
    @State private var showLightWorkout = false

    var activeProgram: WorkoutProgram? {
        programs.first(where: { $0.isActive }) ?? programs.first
    }

    var userProfile: UserProfile? {
        profiles.first
    }

    var thisWeekLogs: [WorkoutLog] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return logs.filter { $0.date >= startOfWeek }
    }

    var todayWorkout: WorkoutDay? {
        guard let program = activeProgram else { return nil }

        let daysSinceStart = Calendar.current.dateComponents(
            [.day], from: program.startDate, to: Date()
        ).day ?? 0

        // FIX: завжди невід'ємне значення
        let safeDays = max(0, daysSinceStart)

        guard !program.weeklySchedule.isEmpty else {
            return program.workoutDays.first
        }

        // FIX: додатковий захист від пустого масиву
        guard !program.workoutDays.isEmpty else { return nil }

        let idx = safeDays % program.weeklySchedule.count

        // FIX: перевірка що idx в межах
        guard idx >= 0 && idx < program.weeklySchedule.count else {
            return program.workoutDays.first
        }

        let scheduleName = program.weeklySchedule[idx]

        // Rest day check
        if scheduleName.lowercased().contains("rest") ||
           scheduleName.lowercased().contains("відпочинок") {
            return nil
        }

        // Find matching workout day
        return program.workoutDays.first { day in
            day.focus.lowercased() == scheduleName.lowercased() ||
            day.dayName.lowercased().contains(scheduleName.lowercased())
        }
    }

    /// Check if AI recommends adjusting today's workout
    var shouldShowAIAdjustmentBanner: Bool {
        guard !dismissedAIBanner else { return false }
        guard let plan = morningBriefing?.todayPlan else { return false }
        guard todayWorkout != nil else { return false }

        // Show banner if AI suggests lighter workout
        let lightTypes = ["light", "rest", "cardio"]
        return lightTypes.contains(plan.type.lowercased())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // AI DAILY READINESS
                    DailyReadinessCard(
                        readiness: dailyReadiness,
                        isLoading: isLoadingReadiness,
                        onRefresh: { loadDailyReadiness() }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // AI ADJUSTMENT BANNER
                    if shouldShowAIAdjustmentBanner, let today = todayWorkout, let plan = morningBriefing?.todayPlan {
                        AdjustedWorkoutBanner(
                            originalWorkout: today,
                            aiSuggestion: plan,
                            onAccept: {
                                acceptAISuggestion(plan: plan, originalWorkout: today)
                            },
                            onKeepOriginal: {
                                ignoreAISuggestion(plan: plan, originalWorkout: today)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }

                    // TODAY SECTION (based on adjustment)
                    if adjustedWorkoutType == "rest" {
                        // Show rest day instead of workout
                        RestDayCard()
                            .padding(.horizontal)
                            .padding(.top, 12)
                    } else if adjustedWorkoutType == "cardio" {
                        // Cardio button
                        CardioTodayCard(onStart: { showCardioView = true })
                            .padding(.horizontal)
                            .padding(.top, 12)
                    } else if let today = todayWorkout {
                        // Regular or light workout
                        JournalTodayCard(
                            day: today,
                            isLightWorkout: adjustedWorkoutType == "light"
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                    } else {
                        RestDayCard()
                            .padding(.horizontal)
                            .padding(.top, 12)
                    }

                    // WEEK PROGRESS
                    WeekProgressSection(program: activeProgram, logs: Array(logs.prefix(7)))
                        .padding(.top, 16)

                    // AI WEEKLY REPORT
                    if thisWeekLogs.count >= 2 {
                        WeeklyReportSection(
                            report: weeklyReport,
                            isLoading: isLoadingReport,
                            onRefresh: { loadWeeklyReport() }
                        )
                        .padding(.top, 16)
                    }

                    // PROGRAM SCHEDULE
                    if let program = activeProgram, !program.workoutDays.isEmpty {
                        ProgramScheduleSection(program: program)
                            .padding(.top, 16)
                    }

                    // HISTORY
                    if !logs.isEmpty {
                        WorkoutHistorySection(logs: Array(logs.prefix(10)))
                            .padding(.top, 16)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationTitle("Тренування")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditor = true
                        } label: {
                            Label("Редагувати програму", systemImage: "pencil")
                        }
                        Button {
                            guard activeProgram != nil else { return }
                            selectedDate = activeProgram?.startDate ?? Date()
                            showDatePicker = true
                        } label: {
                            Label("Змінити дату початку", systemImage: "calendar")
                        }
                        Divider()
                        Button {
                            showProgramPicker = true
                        } label: {
                            Label("Нова програма", systemImage: "plus.circle")
                        }
                        Button("Видалити програму", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showProgramPicker) {
            ProgramPickerView()
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 32) {

                        // Показуємо поточну дату
                        Text(selectedDate.formatted(date: .long, time: .omitted))
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        // WHEEL стиль — не має бага з блокуванням
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .colorScheme(.dark)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        // Швидкі кнопки
                        VStack(spacing: 12) {
                            Button("Сьогодні (\(Date().formatted(date: .abbreviated, time: .omitted)))") {
                                selectedDate = Date()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.12))
                            .foregroundColor(.white)
                            .cornerRadius(14)

                            Button("Завтра") {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.12))
                            .foregroundColor(.white)
                            .cornerRadius(14)

                            Button("Наступний понеділок") {
                                selectedDate = nextMonday()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.12))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top, 24)
                }
                .navigationTitle("Дата початку")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            activeProgram?.startDate = selectedDate
                            try? modelContext.save()
                            showDatePicker = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Скасувати") {
                            showDatePicker = false
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showEditor) {
            if let program = activeProgram {
                WorkoutProgramEditorView(program: program)
            }
        }
        .onAppear {
            if thisWeekLogs.count >= 2 && weeklyReport == nil {
                loadWeeklyReport()
            }
            // Load morning briefing for AI adjustment
            if morningBriefing == nil && todayWorkout != nil {
                loadMorningBriefing()
            }
        }
        .sheet(isPresented: $showRestDayView) {
            RestDayRecoveryView(
                aiSuggestion: morningBriefing?.todayPlan.suggestion ?? "Твоє тіло потребує відпочинку для оптимального відновлення.",
                onDismiss: { showRestDayView = false }
            )
        }
        .sheet(isPresented: $showCardioView) {
            CardioSuggestionView(
                aiSuggestion: morningBriefing?.todayPlan.suggestion ?? "Легке кардіо допоможе прискорити відновлення.",
                onComplete: {
                    showCardioView = false
                    // Log cardio completion
                },
                onSkip: {
                    showCardioView = false
                }
            )
        }
        .confirmationDialog(
            "Видалити програму?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Видалити", role: .destructive) {
                deleteActiveProgram()
            }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Історія тренувань збережеться")
        }
    }

    func deleteActiveProgram() {
        guard let program = activeProgram else { return }
        for day in program.workoutDays {
            for exercise in day.exercises {
                modelContext.delete(exercise)
            }
            modelContext.delete(day)
        }
        modelContext.delete(program)
        try? modelContext.save()
    }

    func loadWeeklyReport() {
        guard !isLoadingReport else { return }
        isLoadingReport = true

        Task {
            do {
                let report = try await LLMService.shared.getWeeklyReport(
                    workoutLogs: thisWeekLogs,
                    profile: userProfile
                )
                await MainActor.run {
                    weeklyReport = report
                    isLoadingReport = false
                }
            } catch {
                print("Weekly report error: \(error)")
                await MainActor.run {
                    isLoadingReport = false
                }
            }
        }
    }

    func nextMonday() -> Date {
        var components = DateComponents()
        components.weekday = 2 // понеділок
        return Calendar.current.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()
    }

    func loadDailyReadiness() {
        guard !isLoadingReadiness else { return }
        isLoadingReadiness = true

        Task {
            let snapshot = HealthSnapshot.mock // TODO: Replace with real HealthKit data
            let readiness = await LLMService.shared.fetchDailyReadiness(
                snapshot: snapshot,
                plannedWorkout: todayWorkout,
                recentWorkouts: Array(logs.prefix(7))
            )
            await MainActor.run {
                dailyReadiness = readiness
                isLoadingReadiness = false
            }
        }
    }

    // MARK: - AI Adjustment Handling

    func loadMorningBriefing() {
        guard !isLoadingBriefing else { return }
        isLoadingBriefing = true

        Task {
            do {
                let snapshot = HealthSnapshot.mock // TODO: Replace with real HealthKit data
                let briefing = try await LLMService.shared.fetchMorningBriefing(
                    snapshot: snapshot,
                    history: nil,
                    plannedWorkout: todayWorkout,
                    recentFeedback: []
                )
                await MainActor.run {
                    morningBriefing = briefing
                    isLoadingBriefing = false
                }
            } catch {
                await MainActor.run {
                    isLoadingBriefing = false
                }
            }
        }
    }

    func acceptAISuggestion(plan: TodayPlan, originalWorkout: WorkoutDay) {
        // Set adjusted workout type
        adjustedWorkoutType = plan.type.lowercased()
        dismissedAIBanner = true

        // Log the decision
        let decision = WorkoutDecisionLog.followed(
            aiType: plan.type,
            aiText: plan.suggestion,
            originalWorkout: originalWorkout.dayName,
            actualType: plan.type.lowercased(),
            recoveryScore: dailyReadiness?.shouldTrain == false ? 0 : 70
        )
        modelContext.insert(decision)
        try? modelContext.save()

        // Navigate to appropriate view
        switch plan.type.lowercased() {
        case "rest":
            showRestDayView = true
        case "cardio":
            showCardioView = true
        case "light":
            showLightWorkout = true
        default:
            break
        }
    }

    func ignoreAISuggestion(plan: TodayPlan, originalWorkout: WorkoutDay) {
        dismissedAIBanner = true

        // Log the decision
        let decision = WorkoutDecisionLog.ignored(
            aiType: plan.type,
            aiText: plan.suggestion,
            originalWorkout: originalWorkout.dayName,
            recoveryScore: dailyReadiness?.shouldTrain == false ? 0 : 70
        )
        modelContext.insert(decision)
        try? modelContext.save()
    }
}

// MARK: - Daily Readiness Card

struct DailyReadinessCard: View {
    let readiness: DailyReadiness?
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("AI Готовність")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.purple)
                        .scaleEffect(0.8)
                } else {
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }

            if let r = readiness {
                // Індикатор готовності
                HStack(spacing: 12) {
                    Circle()
                        .fill(readinessColor(r.intensity))
                        .frame(width: 12, height: 12)
                    Text(r.headline)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                Text(r.reasoning)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.6))
                    .lineLimit(3)

                HStack {
                    Label(r.keyMetric, systemImage: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundColor(.purple)

                    if let warning = r.warning {
                        Spacer()
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .lineLimit(1)
                    }
                }

                // Інтенсивність рекомендації
                HStack {
                    Text("Рекомендація:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(intensityText(r.intensity))
                        .font(.caption.bold())
                        .foregroundColor(readinessColor(r.intensity))
                }
            } else if !isLoading {
                Button {
                    onRefresh()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Аналізувати готовність")
                    }
                    .font(.subheadline)
                    .foregroundColor(.purple)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(white: 0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }

    func readinessColor(_ intensity: String) -> Color {
        switch intensity {
        case "heavy": return .green
        case "moderate": return .blue
        case "light": return .orange
        case "rest": return .red
        default: return .gray
        }
    }

    func intensityText(_ intensity: String) -> String {
        switch intensity {
        case "heavy": return "Важке тренування"
        case "moderate": return "Стандартне тренування"
        case "light": return "Легке тренування"
        case "rest": return "Відпочинок"
        default: return intensity
        }
    }
}

// MARK: - Today Workout Card (Journal)

struct JournalTodayCard: View {
    let day: WorkoutDay
    var isLightWorkout: Bool = false
    @State private var showWorkout = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("СЬОГОДНІ")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .tracking(1.5)

                        if isLightWorkout {
                            LightWorkoutBadge()
                        }
                    }
                    Text(day.dayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(day.focus)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                // Big START button
                Button {
                    showWorkout = true
                } label: {
                    Text("СТАРТ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(25)
                }
            }

            // Light workout info
            if isLightWorkout {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Зменшено: -30% підходів, -20% ваги")
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }

            // Exercise preview list
            VStack(spacing: 8) {
                ForEach(day.exercises.prefix(4)) { ex in
                    HStack {
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 6, height: 6)
                        Text(ex.name)
                            .font(.subheadline)
                            .foregroundColor(Color(white: 0.7))
                        Spacer()
                        if isLightWorkout {
                            // Adjusted sets/reps for light workout
                            let adjustedSets = max(1, Int(Double(ex.sets) * 0.7))
                            Text("\(adjustedSets)×\(ex.repsDisplay)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("\(ex.sets)×\(ex.repsDisplay)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                if day.exercises.count > 4 {
                    Text("+ ще \(day.exercises.count - 4) вправ")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isLightWorkout ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showWorkout) {
            ActiveWorkoutView(workoutDay: day, isLightWorkout: isLightWorkout)
        }
    }
}

// MARK: - Cardio Today Card

struct CardioTodayCard: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("СЬОГОДНІ")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .tracking(1.5)

                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text("Кардіо")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Text("Активне відновлення")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("20-30 хв Zone 2 кардіо")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()

                Button(action: onStart) {
                    Text("ДЕТАЛІ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }

            // Quick options
            HStack(spacing: 12) {
                CardioQuickOption(icon: "figure.walk", title: "Прогулянка")
                CardioQuickOption(icon: "figure.outdoor.cycle", title: "Велосипед")
                CardioQuickOption(icon: "figure.elliptical", title: "Еліптик")
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
        )
    }
}

struct CardioQuickOption: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(white: 0.12))
        .cornerRadius(8)
    }
}

// MARK: - Rest Day Card

struct RestDayCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue.opacity(0.7))

            VStack(spacing: 4) {
                Text("День відпочинку")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("Відновлення — ключ до прогресу")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(white: 0.08))
        .cornerRadius(20)
    }
}

// MARK: - Week Progress Section

struct WeekProgressSection: View {
    let program: WorkoutProgram?
    let logs: [WorkoutLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Цей тиждень")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(thisWeekCount)/\(targetCount)")
                    .font(.subheadline)
                    .foregroundColor(thisWeekCount >= targetCount ? .green : .blue)
            }

            HStack(spacing: 8) {
                ForEach(weekDays, id: \.date) { dayInfo in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(dayInfo.isCompleted ? Color.green :
                                  dayInfo.isToday ? Color.blue :
                                  dayInfo.isRestDay ? Color(white: 0.15) :
                                  Color(white: 0.12))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Group {
                                    if dayInfo.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)
                                    } else if dayInfo.isToday && !dayInfo.isRestDay {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            )
                        Text(dayInfo.label)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(white: 0.06))
        .padding(.horizontal)
    }

    var targetCount: Int {
        program?.frequencyDays ?? 4
    }

    var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return logs.filter { $0.date >= startOfWeek }.count
    }

    struct DayInfo {
        let date: Date
        let label: String
        let isToday: Bool
        let isCompleted: Bool
        let isRestDay: Bool
    }

    var weekDays: [DayInfo] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        let dayLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let isToday = calendar.isDateInToday(date)
            let isCompleted = logs.contains { calendar.isDate($0.date, inSameDayAs: date) }

            // Check if rest day based on program schedule
            var isRestDay = false
            if let program = program, !program.weeklySchedule.isEmpty {
                let idx = offset % program.weeklySchedule.count
                // FIX: перевірка що idx в межах
                if idx >= 0 && idx < program.weeklySchedule.count {
                    let scheduleName = program.weeklySchedule[idx]
                    isRestDay = scheduleName.lowercased().contains("rest") ||
                               scheduleName.lowercased().contains("відпочинок")
                }
            }

            return DayInfo(
                date: date,
                label: dayLabels[offset],
                isToday: isToday,
                isCompleted: isCompleted,
                isRestDay: isRestDay
            )
        }
    }
}

// MARK: - Program Schedule Section

struct ProgramScheduleSection: View {
    let program: WorkoutProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Програма: \(program.name)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(program.workoutDays) { day in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(day.dayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            Text(day.focus)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(day.exercises.count) вправ")
                                .font(.caption2)
                                .foregroundColor(Color(white: 0.5))
                        }
                        .frame(width: 140)
                        .padding()
                        .background(Color(white: 0.08))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Workout History Section

struct WorkoutHistorySection: View {
    let logs: [WorkoutLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Історія")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(logs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.workoutDayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                            Text(log.formattedDate)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(log.formattedDuration)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text(log.formattedVolume)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.06))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Weekly Report Section

struct WeeklyReportSection: View {
    let report: WeeklyReport?
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("AI Звіт тижня")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Text("Аналізую тренування...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
                .background(Color(white: 0.08))
                .cornerRadius(16)
                .padding(.horizontal)
            } else if let report = report {
                WeeklyReportCard(report: report)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Натисніть для аналізу")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.08))
                .cornerRadius(16)
                .padding(.horizontal)
                .onTapGesture { onRefresh() }
            }
        }
    }
}

// MARK: - Weekly Report Card

struct WeeklyReportCard: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            Text(report.weekSummary)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Top Progress
            if !report.topProgress.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Text("Найкращий прогрес")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.green)
                    }

                    ForEach(report.topProgress) { progress in
                        HStack {
                            Text(progress.exercise)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text(progress.insight)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
            }

            // Concerns
            if !report.concerns.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Увага")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.orange)
                    }

                    ForEach(report.concerns, id: \.self) { concern in
                        Text("• \(concern)")
                            .font(.caption)
                            .foregroundColor(Color(white: 0.7))
                    }
                }
            }

            // Deload Warning
            if report.deloadNeeded {
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.red)
                    Text("Рекомендовано розвантажувальний тиждень")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.red)
                }
                .padding(10)
                .background(Color.red.opacity(0.15))
                .cornerRadius(10)
            }

            // Next Week Focus
            if !report.nextWeekFocus.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Фокус наступного тижня")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                    Text(report.nextWeekFocus)
                        .font(.caption)
                        .foregroundColor(Color(white: 0.7))
                }
            }

            // Motivational Note
            if !report.motivationalNote.isEmpty {
                Text("💪 \(report.motivationalNote)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }
}


#Preview {
    WorkoutJournalView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutLog.self])
}
