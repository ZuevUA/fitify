//
//  WorkoutOnboardingViewModel.swift
//  Fitify
//

import Foundation
import SwiftData

@Observable
final class WorkoutOnboardingViewModel {
    private var modelContext: ModelContext?

    // Current step
    var currentStep: OnboardingStep = .goal
    var isGeneratingProgram = false
    var generationError: String?
    var generatedProgram: WorkoutProgram?

    // User inputs
    var selectedGoal: WorkoutGoal?
    var selectedExperience: ExperienceLevel?
    var selectedGender: Gender?
    var age: Int = 25
    var weightKg: Double = 70
    var trainingDaysPerWeek: Int = 4
    var sessionDurationMinutes: Int = 60
    var selectedSleep: SleepRange?
    var calculatedWeeklyVolume: Int = 14
    var adjustedWeeklyVolume: Int = 14
    var wantsPriorityMuscles: Bool = false
    var selectedPriorityMuscles: Set<MuscleGroup> = []

    var totalSteps: Int { OnboardingStep.allCases.count }

    var currentStepIndex: Int {
        OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    var progress: Double {
        Double(currentStepIndex) / Double(totalSteps - 1)
    }

    var canContinue: Bool {
        switch currentStep {
        case .goal: return selectedGoal != nil
        case .experience: return selectedExperience != nil
        case .gender: return selectedGender != nil
        case .age: return age >= 14 && age <= 100
        case .weight: return weightKg >= 30 && weightKg <= 300
        case .frequency: return trainingDaysPerWeek >= 2 && trainingDaysPerWeek <= 7  // Виправлено: 2-7 днів
        case .duration: return sessionDurationMinutes >= 0  // Виправлено: 0 = "Скільки потрібно" - валідний вибір
        case .sleep: return selectedSleep != nil
        case .volume: return true
        case .muscleFocus: return true
        case .priorityMuscles: return true
        case .generating: return false
        case .programReady: return generatedProgram != nil
        }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func nextStep() {
        guard let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep).map({ $0 + 1 }),
              nextIndex < OnboardingStep.allCases.count else { return }

        // Skip priority muscles if user doesn't want them
        if currentStep == .muscleFocus && !wantsPriorityMuscles {
            currentStep = .generating
            Task { await generateProgram() }
            return
        }

        if currentStep == .priorityMuscles {
            currentStep = .generating
            Task { await generateProgram() }
            return
        }

        if currentStep == .sleep {
            calculateVolume()
        }

        currentStep = OnboardingStep.allCases[nextIndex]
    }

    func previousStep() {
        guard let prevIndex = OnboardingStep.allCases.firstIndex(of: currentStep).map({ $0 - 1 }),
              prevIndex >= 0 else { return }

        // Skip priority muscles going back
        if currentStep == .generating && !wantsPriorityMuscles {
            currentStep = .muscleFocus
            return
        }

        currentStep = OnboardingStep.allCases[prevIndex]
    }

    func calculateVolume() {
        guard let experience = selectedExperience,
              let sleep = selectedSleep else { return }

        let baseRange = experience.weeklyVolumeRange
        let midPoint = (baseRange.lowerBound + baseRange.upperBound) / 2

        var volume = Double(midPoint)
        volume *= sleep.volumeMultiplier

        // Adjust for training frequency
        let frequencyBonus = Double(trainingDaysPerWeek - 3) * 0.05
        volume *= (1.0 + frequencyBonus)

        // Adjust for age
        if age > 40 {
            volume *= 0.9
        } else if age > 50 {
            volume *= 0.8
        }

        calculatedWeeklyVolume = Int(volume.rounded())
        adjustedWeeklyVolume = calculatedWeeklyVolume
    }

    func generateProgram() async {
        isGeneratingProgram = true
        generationError = nil

        // Small delay for UI animation
        try? await Task.sleep(nanoseconds: 500_000_000)

        do {
            let profile = buildUserProfile()
            print("🚀 Generating program for profile:")
            print("   Goal: \(profile.goal)")
            print("   Experience: \(profile.experience)")
            print("   Days/week: \(profile.trainingDaysPerWeek)")
            print("   Session duration: \(profile.sessionDurationMinutes) min")

            // Select best matching template
            let template = NippardProgramSelector.selectBestProgram(for: profile)
            print("📋 Selected template: \(template.name)")

            // Create WorkoutProgram from template
            let program = NippardProgramSelector.createWorkoutProgram(from: template, profile: profile)
            generatedProgram = program

            print("✅ Program created: \(program.name)")

            // Save to SwiftData
            if let context = modelContext {
                print("💾 Saving to SwiftData...")
                print("   Program: \(program.name), isActive: \(program.isActive)")
                print("   Days count: \(program.workoutDays.count)")
                program.workoutDays.forEach { day in
                    print("   - \(day.dayName): \(day.exercises.count) exercises")
                }

                context.insert(profile)
                context.insert(program)
                try context.save()
                print("✅ Successfully saved to SwiftData!")
            } else {
                print("❌ modelContext is nil! Cannot save.")
            }

            currentStep = .programReady
        } catch {
            print("❌ Error: \(error)")
            print("   Type: \(type(of: error))")
            generationError = error.localizedDescription
        }

        isGeneratingProgram = false
    }

    func buildUserProfile() -> UserProfile {
        let profile = UserProfile(
            goal: selectedGoal ?? .buildMuscle,
            experience: selectedExperience ?? .beginner,
            gender: selectedGender ?? .male,
            age: age,
            weightKg: weightKg,
            trainingDaysPerWeek: trainingDaysPerWeek,
            sessionDurationMinutes: sessionDurationMinutes,
            priorityMuscles: selectedPriorityMuscles.map { $0.rawValue },
            weeklyVolumePreference: .medium,
            sleepHours: selectedSleep ?? .over7,
            calculatedWeeklyVolume: adjustedWeeklyVolume,
            onboardingCompleted: true
        )
        return profile
    }

    func completeOnboarding() {
        // Mark onboarding as completed in UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedWorkoutOnboarding")
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case goal
    case experience
    case gender
    case age
    case weight
    case frequency
    case duration
    case sleep
    case volume
    case muscleFocus
    case priorityMuscles
    case generating
    case programReady

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .goal: return "Ціль"
        case .experience: return "Досвід"
        case .gender: return "Стать"
        case .age: return "Вік"
        case .weight: return "Вага"
        case .frequency: return "Частота тренувань"
        case .duration: return "Тривалість"
        case .sleep: return "Сон"
        case .volume: return "Тижневий об'єм"
        case .muscleFocus: return "Фокус м'язів"
        case .priorityMuscles: return "Пріоритетні м'язи"
        case .generating: return "Підбираємо програму"
        case .programReady: return "Програма готова"
        }
    }
}
