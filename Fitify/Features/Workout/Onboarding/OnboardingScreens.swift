//
//  OnboardingScreens.swift
//  Fitify
//

import SwiftUI
import UIKit

// MARK: - Goal Screen

struct GoalScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Ціль",
                subtitle: "Який твій головний фокус зараз?",
                onBack: nil
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(WorkoutGoal.allCases) { goal in
                        OnboardingOptionCard(
                            title: goal.displayName,
                            subtitle: goal.description,
                            iconName: goal.iconName,
                            isSelected: viewModel.selectedGoal == goal
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedGoal = goal
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Experience Screen

struct ExperienceScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Досвід",
                subtitle: "Скільки часу ти тренуєшся стабільно?",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ExperienceLevel.allCases) { level in
                        OnboardingOptionCard(
                            title: level.displayName,
                            subtitle: level.description,
                            isSelected: viewModel.selectedExperience == level
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedExperience = level
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Gender Screen

struct GenderScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Стать",
                subtitle: nil,
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Gender.allCases) { gender in
                        OnboardingOptionCard(
                            title: gender.displayName,
                            isSelected: viewModel.selectedGender == gender
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedGender = gender
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Age Screen

struct AgeScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    private var ageBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.age) },
            set: { viewModel.age = Int($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Вік",
                subtitle: nil,
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            Spacer()

            // Ruler picker with big number
            RulerPickerView(
                value: ageBinding,
                range: 16...80,
                step: 1,
                unit: "років"
            )

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Weight Screen

struct WeightScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel
    @State private var isKg = true

    private var displayWeight: Double {
        isKg ? viewModel.weightKg : viewModel.weightKg * 2.20462
    }

    private var weightBinding: Binding<Double> {
        Binding(
            get: { isKg ? viewModel.weightKg : viewModel.weightKg * 2.20462 },
            set: { newValue in
                viewModel.weightKg = isKg ? newValue : newValue / 2.20462
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Вага",
                subtitle: "Вага впливає на розрахунок об'єму та прогресу",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            Spacer()

            // Unit toggle
            HStack(spacing: 0) {
                Button {
                    withAnimation { isKg = true }
                } label: {
                    Text("кг")
                        .font(.headline)
                        .foregroundStyle(isKg ? .black : .white)
                        .frame(width: 60, height: 40)
                        .background(isKg ? Color.white : Color(hex: "1C1C1E"))
                }

                Button {
                    withAnimation { isKg = false }
                } label: {
                    Text("lbs")
                        .font(.headline)
                        .foregroundStyle(!isKg ? .black : .white)
                        .frame(width: 60, height: 40)
                        .background(!isKg ? Color.white : Color(hex: "1C1C1E"))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 24)

            // Ruler picker with big number
            RulerPickerView(
                value: weightBinding,
                range: isKg ? 40...200 : 88...440,
                step: isKg ? 0.5 : 1,
                unit: isKg ? "кг" : "lbs"
            )

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Training Frequency Screen

struct TrainingFrequencyScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    private var frequencyBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.trainingDaysPerWeek) },
            set: { viewModel.trainingDaysPerWeek = Int($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Частота тренувань",
                subtitle: "Скільки днів на тиждень ти тренуєшся?",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            Spacer()

            // Ruler picker with big number
            RulerPickerView(
                value: frequencyBinding,
                range: 2...7,
                step: 1,
                unit: ""
            )

            Text("тренувань на тиждень")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            // Recommended split
            Text("Рекомендований спліт: \(recommendedSplit)")
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding(.top, 24)

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }

    private var recommendedSplit: String {
        switch viewModel.trainingDaysPerWeek {
        case 2, 3: return "Full Body"
        case 4: return "Upper / Lower"
        case 5, 6, 7: return "Push / Pull / Legs"
        default: return "Push / Pull / Legs"
        }
    }
}

// MARK: - Duration Screen

struct DurationScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    private let options = [
        (30, "30 хв"),
        (45, "45 хв"),
        (60, "60 хв"),
        (0, "Скільки потрібно")
    ]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Тривалість",
                subtitle: "Скільки часу ти готовий тренуватись?",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(options, id: \.0) { option in
                        OnboardingOptionCard(
                            title: option.1,
                            isSelected: viewModel.sessionDurationMinutes == option.0
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.sessionDurationMinutes = option.0
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Sleep Screen

struct SleepScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Сон",
                subtitle: "Скільки ти зазвичай спиш?",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SleepRange.allCases) { range in
                        OnboardingOptionCard(
                            title: range.displayName,
                            subtitle: range.recoveryDescription,
                            iconName: sleepIcon(for: range),
                            isSelected: viewModel.selectedSleep == range
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedSleep = range
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            Spacer()

            // Custom button text
            Button {
                viewModel.calculateVolume()
                withAnimation { viewModel.nextStep() }
            } label: {
                Text("Розрахувати мій тижневий об'єм")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.canContinue ? Color.white : Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func sleepIcon(for range: SleepRange) -> String {
        switch range {
        case .under5: return "moon.zzz"
        case .fiveToSeven: return "moon"
        case .over7: return "moon.stars"
        }
    }
}

// MARK: - Weekly Volume Screen

struct WeeklyVolumeScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.adjustedWeeklyVolume) },
            set: { viewModel.adjustedWeeklyVolume = Int($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Твій оптимальний тижневий об'єм",
                subtitle: nil,
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            Spacer()

            // Ruler picker with big number
            RulerPickerView(
                value: volumeBinding,
                range: 6...25,
                step: 1,
                unit: "підходів"
            )

            Text("на м'яз / тиждень")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            // Explanation
            Text("На основі твоїх даних це діапазон підходів\nщо максимізує прогрес")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.horizontal, 32)

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canContinue) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }
}

// MARK: - Muscle Focus Screen

struct MuscleFocusScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Фокус м'язів",
                subtitle: "Хочеш пріоритизувати конкретні м'язи?",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            Spacer()

            // Body silhouette placeholder
            Image(systemName: "figure.stand")
                .font(.system(size: 160))
                .foregroundStyle(.white.opacity(0.3))

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.wantsPriorityMuscles = true
                    withAnimation { viewModel.nextStep() }
                } label: {
                    Text("Обрати м'язи")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    viewModel.wantsPriorityMuscles = false
                    withAnimation { viewModel.nextStep() }
                } label: {
                    Text("Тренувати все рівномірно")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "1C1C1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Priority Muscles Screen

struct PriorityMusclesScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: "Пріоритетні м'язи",
                subtitle: "Обери до 2 м'язів для додаткового фокусу",
                onBack: { withAnimation { viewModel.previousStep() } }
            )

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MuscleGroup.allCases) { muscle in
                        MuscleChip(
                            name: muscle.displayName,
                            isSelected: viewModel.selectedPriorityMuscles.contains(muscle)
                        ) {
                            toggleMuscle(muscle)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                withAnimation { viewModel.nextStep() }
            }
        }
    }

    private func toggleMuscle(_ muscle: MuscleGroup) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewModel.selectedPriorityMuscles.contains(muscle) {
                viewModel.selectedPriorityMuscles.remove(muscle)
            } else if viewModel.selectedPriorityMuscles.count < 2 {
                viewModel.selectedPriorityMuscles.insert(muscle)
            }
        }
    }
}

struct MuscleChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white : Color(hex: "1C1C1E"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Generating Program Screen

struct GeneratingProgramScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated orb
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .offset(x: 60 * cos(Double(index) * .pi / 4 + rotation),
                                y: 60 * sin(Double(index) * .pi / 4 + rotation))
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue, .purple],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = .pi * 2
                }
            }

            VStack(spacing: 12) {
                Text("Підбираємо програму")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("На основі твоїх даних...")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let error = viewModel.generationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 8)

                    Button("Спробувати знову") {
                        Task { await viewModel.generateProgram() }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Program Ready Screen

struct ProgramReadyScreen: View {
    @Bindable var viewModel: WorkoutOnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Твоя програма готова!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 48)

            // Program cards
            if let program = viewModel.generatedProgram {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(program.workoutDays) { day in
                            WorkoutDayCard(day: day)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }

            Spacer()

            Button(action: onComplete) {
                Text("Почати програму")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct WorkoutDayCard: View {
    let day: WorkoutDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.dayName)
                .font(.headline)
                .foregroundStyle(.white)

            Text(day.focus)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text("~\(day.estimatedDurationMinutes) хв")
                    .font(.caption)

                Spacer()

                Text("\(day.exercises.count) вправ")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1C1C1E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Ruler Picker View

struct RulerPickerView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    @State private var dragStartValue: Double = 0
    @State private var isDragging: Bool = false
    @State private var isEditingText: Bool = false
    @State private var textInput: String = ""

    // Чутливість: більше = повільніше = точніше
    private let pixelsPerStep: CGFloat = 20

    private var displayText: String {
        step < 1 ? String(format: "%.1f", value) : "\(Int(value))"
    }

    var body: some View {
        VStack(spacing: 8) {

            // Велике число — тап для редагування тексту
            if isEditingText {
                // Текстове поле
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    TextField("", text: $textInput)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(step < 1 ? .decimalPad : .numberPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                        .onSubmit { commitTextInput() }
                    Text(unit)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                }
                .frame(maxWidth: .infinity)

                // Кнопки OK / Скасувати
                HStack(spacing: 16) {
                    Button("Скасувати") {
                        isEditingText = false
                        textInput = ""
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.15))
                    .cornerRadius(20)

                    Button("OK") { commitTextInput() }
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                }

            } else {
                // Звичайне відображення числа
                Button {
                    textInput = displayText
                    isEditingText = true
                } label: {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(displayText)
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(unit)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                // Підказка "тап для введення"
                Text("Натисни на число для введення вручну")
                    .font(.caption2)
                    .foregroundColor(Color(white: 0.35))
            }

            Spacer().frame(height: 12)

            // Ruler (показуємо тільки коли не редагуємо текст)
            if !isEditingText {
                GeometryReader { geo in
                    let centerX = geo.size.width / 2

                    ZStack {
                        Canvas { context, size in
                            let totalSteps = Int((range.upperBound - range.lowerBound) / step)

                            for i in 0...totalSteps {
                                let tickVal = range.lowerBound + Double(i) * step
                                let offsetPx = CGFloat(tickVal - value) / step * pixelsPerStep
                                let x = centerX + offsetPx

                                guard x > -30 && x < size.width + 30 else { continue }

                                let isMajor = i % 5 == 0
                                let tickH: CGFloat = isMajor ? 32 : 16

                                var path = Path()
                                path.move(to: CGPoint(x: x, y: 8))
                                path.addLine(to: CGPoint(x: x, y: 8 + tickH))
                                context.stroke(
                                    path,
                                    with: .color(Color(white: isMajor ? 0.75 : 0.4)),
                                    lineWidth: isMajor ? 2 : 1.5
                                )

                                if isMajor {
                                    let label = step < 1
                                        ? String(format: "%.0f", tickVal)
                                        : "\(Int(tickVal))"
                                    context.draw(
                                        Text(label)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(white: 0.45)),
                                        at: CGPoint(x: x, y: 8 + tickH + 14)
                                    )
                                }
                            }
                        }
                        .frame(height: 72)

                        // Центральний маркер
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 2, height: 42)
                            Spacer()
                        }
                        .frame(height: 72)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    dragStartValue = value
                                }
                                // Повільний рух: ділимо translation на pixelsPerStep
                                let deltaSteps = -gesture.translation.width / pixelsPerStep
                                let rawValue = dragStartValue + deltaSteps * step
                                let snapped = (rawValue / step).rounded() * step
                                let clamped = min(max(snapped, range.lowerBound), range.upperBound)

                                if clamped != value {
                                    value = clamped
                                    UIImpactFeedbackGenerator(style: .light)
                                        .impactOccurred(intensity: 0.4)
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                dragStartValue = value
                            }
                    )
                }
                .frame(height: 72)
            }
        }
        .onAppear { dragStartValue = value }
        .animation(.none, value: value)
    }

    private func commitTextInput() {
        let clean = textInput.replacingOccurrences(of: ",", with: ".")
        if let parsed = Double(clean) {
            let snapped = (parsed / step).rounded() * step
            value = min(max(snapped, range.lowerBound), range.upperBound)
        }
        isEditingText = false
        textInput = ""
    }
}
