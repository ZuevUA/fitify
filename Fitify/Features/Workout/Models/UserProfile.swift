//
//  UserProfile.swift
//  Fitify
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String?
    var goal: String // WorkoutGoal raw value
    var experience: String // ExperienceLevel raw value
    var gender: String // Gender raw value
    var age: Int
    var weightKg: Double
    var trainingDaysPerWeek: Int
    var sessionDurationMinutes: Int
    var priorityMuscles: [String]
    var weeklyVolumePreference: String // VolumePreference raw value
    var sleepHours: String // SleepRange raw value
    var calculatedWeeklyVolume: Int
    var onboardingCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String? = nil,
        goal: WorkoutGoal = .buildMuscle,
        experience: ExperienceLevel = .beginner,
        gender: Gender = .male,
        age: Int = 25,
        weightKg: Double = 70,
        trainingDaysPerWeek: Int = 4,
        sessionDurationMinutes: Int = 60,
        priorityMuscles: [String] = [],
        weeklyVolumePreference: VolumePreference = .medium,
        sleepHours: SleepRange = .over7,
        calculatedWeeklyVolume: Int = 0,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.goal = goal.rawValue
        self.experience = experience.rawValue
        self.gender = gender.rawValue
        self.age = age
        self.weightKg = weightKg
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.sessionDurationMinutes = sessionDurationMinutes
        self.priorityMuscles = priorityMuscles
        self.weeklyVolumePreference = weeklyVolumePreference.rawValue
        self.sleepHours = sleepHours.rawValue
        self.calculatedWeeklyVolume = calculatedWeeklyVolume
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var workoutGoal: WorkoutGoal {
        get { WorkoutGoal(rawValue: goal) ?? .buildMuscle }
        set { goal = newValue.rawValue }
    }

    var experienceLevel: ExperienceLevel {
        get { ExperienceLevel(rawValue: experience) ?? .beginner }
        set { experience = newValue.rawValue }
    }

    var userGender: Gender {
        get { Gender(rawValue: gender) ?? .male }
        set { gender = newValue.rawValue }
    }

    var volumePreference: VolumePreference {
        get { VolumePreference(rawValue: weeklyVolumePreference) ?? .medium }
        set { weeklyVolumePreference = newValue.rawValue }
    }

    var sleepRange: SleepRange {
        get { SleepRange(rawValue: sleepHours) ?? .over7 }
        set { sleepHours = newValue.rawValue }
    }
}

// MARK: - Enums

enum WorkoutGoal: String, CaseIterable, Identifiable {
    case buildMuscle = "buildMuscle"
    case loseFat = "loseFat"
    case strength = "strength"
    case recomp = "recomp"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .buildMuscle: return "Набір м'язів"
        case .loseFat: return "Схуднення"
        case .strength: return "Сила та результат"
        case .recomp: return "Підтримка / Рекомп"
        }
    }

    var description: String {
        switch self {
        case .buildMuscle: return "Максимальний ріст м'язової маси"
        case .loseFat: return "Втрата жиру зі збереженням м'язів"
        case .strength: return "Збільшення силових показників"
        case .recomp: return "Одночасна втрата жиру та ріст м'язів"
        }
    }

    var iconName: String {
        switch self {
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .loseFat: return "flame.fill"
        case .strength: return "bolt.fill"
        case .recomp: return "arrow.triangle.2.circlepath"
        }
    }
}

enum ExperienceLevel: String, CaseIterable, Identifiable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Початківець"
        case .intermediate: return "Середній рівень"
        case .advanced: return "Досвідчений"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Менше 1 року"
        case .intermediate: return "1-3 роки"
        case .advanced: return "3+ роки"
        }
    }

    var weeklyVolumeRange: ClosedRange<Int> {
        switch self {
        case .beginner: return 10...12
        case .intermediate: return 12...16
        case .advanced: return 16...20
        }
    }
}

enum Gender: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Чоловік"
        case .female: return "Жінка"
        case .other: return "Інше"
        }
    }
}

enum VolumePreference: String, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Низький"
        case .medium: return "Середній"
        case .high: return "Високий"
        }
    }

    var multiplier: Double {
        switch self {
        case .low: return 0.85
        case .medium: return 1.0
        case .high: return 1.15
        }
    }
}

enum SleepRange: String, CaseIterable, Identifiable {
    case under5 = "under5"
    case fiveToSeven = "fiveToSeven"
    case over7 = "over7"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .under5: return "Менше 5 годин"
        case .fiveToSeven: return "5-7 годин"
        case .over7: return "Більше 7 годин"
        }
    }

    var recoveryDescription: String {
        switch self {
        case .under5: return "Обмежене відновлення"
        case .fiveToSeven: return "Помірне відновлення"
        case .over7: return "Оптимальне відновлення"
        }
    }

    var volumeMultiplier: Double {
        switch self {
        case .under5: return 0.7
        case .fiveToSeven: return 0.85
        case .over7: return 1.0
        }
    }
}

// MARK: - Muscle Groups

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "chest"
    case lats = "lats"
    case frontDelts = "frontDelts"
    case rearDelts = "rearDelts"
    case sideDelts = "sideDelts"
    case biceps = "biceps"
    case triceps = "triceps"
    case traps = "traps"
    case forearms = "forearms"
    case quads = "quads"
    case hamstrings = "hamstrings"
    case glutes = "glutes"
    case calves = "calves"
    case adductors = "adductors"
    case abs = "abs"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Груди"
        case .lats: return "Широчайші"
        case .frontDelts: return "Передні дельти"
        case .rearDelts: return "Задні дельти"
        case .sideDelts: return "Бічні дельти"
        case .biceps: return "Біцепс"
        case .triceps: return "Трицепс"
        case .traps: return "Пастки"
        case .forearms: return "Передпліччя"
        case .quads: return "Квадрицепс"
        case .hamstrings: return "Задня поверхня"
        case .glutes: return "Сідниці"
        case .calves: return "Ікри"
        case .adductors: return "Привідні"
        case .abs: return "Прес"
        }
    }
}

// MARK: - Volume Calculator

extension UserProfile {
    func calculateOptimalWeeklyVolume() -> Int {
        let baseVolume = experienceLevel.weeklyVolumeRange
        let midPoint = (baseVolume.lowerBound + baseVolume.upperBound) / 2

        var volume = Double(midPoint)

        // Adjust for sleep
        volume *= sleepRange.volumeMultiplier

        // Adjust for volume preference
        volume *= volumePreference.multiplier

        // Adjust for training frequency (more days = can handle more volume per muscle)
        let frequencyBonus = Double(trainingDaysPerWeek - 3) * 0.05
        volume *= (1.0 + frequencyBonus)

        // Adjust for age (slight reduction for older athletes)
        if age > 40 {
            volume *= 0.9
        } else if age > 50 {
            volume *= 0.8
        }

        return Int(volume.rounded())
    }

    func recommendedSplit() -> String {
        switch trainingDaysPerWeek {
        case 3: return "Full Body"
        case 4: return "Upper-Lower"
        case 5, 6: return "PPL"
        default: return "PPL"
        }
    }
}
