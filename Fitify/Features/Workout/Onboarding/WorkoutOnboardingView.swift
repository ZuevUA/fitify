//
//  WorkoutOnboardingView.swift
//  Fitify
//

import SwiftUI
import SwiftData

struct WorkoutOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WorkoutOnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if viewModel.currentStep != .generating && viewModel.currentStep != .programReady {
                    OnboardingProgressBar(progress: viewModel.progress)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                // Content
                currentStepView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .goal:
            GoalScreen(viewModel: viewModel)
        case .experience:
            ExperienceScreen(viewModel: viewModel)
        case .gender:
            GenderScreen(viewModel: viewModel)
        case .age:
            AgeScreen(viewModel: viewModel)
        case .weight:
            WeightScreen(viewModel: viewModel)
        case .frequency:
            TrainingFrequencyScreen(viewModel: viewModel)
        case .duration:
            DurationScreen(viewModel: viewModel)
        case .sleep:
            SleepScreen(viewModel: viewModel)
        case .volume:
            WeeklyVolumeScreen(viewModel: viewModel)
        case .muscleFocus:
            MuscleFocusScreen(viewModel: viewModel)
        case .priorityMuscles:
            PriorityMusclesScreen(viewModel: viewModel)
        case .generating:
            GeneratingProgramScreen(viewModel: viewModel)
        case .programReady:
            ProgramReadyScreen(viewModel: viewModel, onComplete: {
                viewModel.completeOnboarding()
                onComplete()
            })
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 3)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Reusable Components

struct OnboardingHeader: View {
    let title: String
    var subtitle: String? = nil
    let onBack: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 8)
            }

            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

struct OnboardingContinueButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Продовжити")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.white : Color.white.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

struct OnboardingOptionCard: View {
    let title: String
    var subtitle: String? = nil
    var iconName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .black : .white)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .black : .white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(isSelected ? .black.opacity(0.7) : .secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.black)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.white : Color(hex: "1C1C1E"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
