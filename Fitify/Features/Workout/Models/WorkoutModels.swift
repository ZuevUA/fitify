//
//  WorkoutModels.swift
//  Fitify
//

import Foundation
import SwiftData

// MARK: - Workout Program

@Model
final class WorkoutProgram {
    var id: UUID
    var name: String
    var splitType: String
    var weeklyVolumeSummary: String
    var progressionStrategy: String
    var deloadProtocol: String
    var aiNotes: String
    var weeklySchedule: [String]
    var createdAt: Date
    var startDate: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade)
    var workoutDays: [WorkoutDay]

    var frequencyDays: Int {
        // Count non-rest days in the weekly schedule
        if weeklySchedule.isEmpty {
            return workoutDays.count
        }
        return weeklySchedule.filter { day in
            !day.lowercased().contains("rest") &&
            !day.lowercased().contains("відпочинок")
        }.count
    }

    init(
        id: UUID = UUID(),
        name: String,
        splitType: String,
        weeklyVolumeSummary: String = "",
        progressionStrategy: String = "",
        deloadProtocol: String = "",
        aiNotes: String = "",
        weeklySchedule: [String] = [],
        workoutDays: [WorkoutDay] = [],
        startDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.splitType = splitType
        self.weeklyVolumeSummary = weeklyVolumeSummary
        self.progressionStrategy = progressionStrategy
        self.deloadProtocol = deloadProtocol
        self.aiNotes = aiNotes
        self.weeklySchedule = weeklySchedule
        self.workoutDays = workoutDays
        self.createdAt = Date()
        self.startDate = startDate
        self.isActive = isActive
    }
}

// MARK: - Workout Day

@Model
final class WorkoutDay {
    var id: UUID
    var dayName: String
    var focus: String
    var estimatedDurationMinutes: Int
    var orderIndex: Int

    @Relationship(deleteRule: .cascade)
    var exercises: [Exercise]

    @Relationship(inverse: \WorkoutProgram.workoutDays)
    var program: WorkoutProgram?

    init(
        id: UUID = UUID(),
        dayName: String,
        focus: String,
        estimatedDurationMinutes: Int = 60,
        orderIndex: Int = 0,
        exercises: [Exercise] = []
    ) {
        self.id = id
        self.dayName = dayName
        self.focus = focus
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.orderIndex = orderIndex
        self.exercises = exercises
    }
}

// MARK: - Exercise

@Model
final class Exercise {
    var id: UUID
    var name: String
    var nameEn: String
    var sets: Int
    var repsMin: Int
    var repsMax: Int
    var rir: Int
    var restSeconds: Int
    var notes: String
    var progressionNote: String
    var muscleGroup: String
    var exerciseType: String // compound/isolation
    var orderIndex: Int
    var suggestedWeightKg: Double?  // Recommended weight for next workout

    @Relationship(inverse: \WorkoutDay.exercises)
    var workoutDay: WorkoutDay?

    init(
        id: UUID = UUID(),
        name: String,
        nameEn: String = "",
        sets: Int = 3,
        repsMin: Int = 8,
        repsMax: Int = 12,
        rir: Int = 2,
        restSeconds: Int = 120,
        notes: String = "",
        progressionNote: String = "",
        muscleGroup: String = "",
        exerciseType: String = "compound",
        orderIndex: Int = 0,
        suggestedWeightKg: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.sets = sets
        self.repsMin = repsMin
        self.repsMax = repsMax
        self.rir = rir
        self.restSeconds = restSeconds
        self.notes = notes
        self.progressionNote = progressionNote
        self.muscleGroup = muscleGroup
        self.exerciseType = exerciseType
        self.orderIndex = orderIndex
        self.suggestedWeightKg = suggestedWeightKg
    }

    var repsDisplay: String {
        if repsMin == repsMax {
            return "\(repsMin)"
        }
        return "\(repsMin)-\(repsMax)"
    }

    var restDisplay: String {
        if restSeconds >= 60 {
            let minutes = restSeconds / 60
            let seconds = restSeconds % 60
            if seconds == 0 {
                return "\(minutes) хв"
            }
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(restSeconds) сек"
    }
}

// MARK: - Workout Log

@Model
final class WorkoutLog {
    var id: UUID
    var date: Date
    var workoutDayId: UUID
    var workoutDayName: String
    var durationMinutes: Int
    var totalVolume: Double // weight × reps
    var notes: String
    var aiRecommendationId: UUID?

    @Relationship(deleteRule: .cascade)
    var completedSets: [CompletedSet]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        workoutDayId: UUID,
        workoutDayName: String,
        durationMinutes: Int = 0,
        totalVolume: Double = 0,
        notes: String = "",
        completedSets: [CompletedSet] = []
    ) {
        self.id = id
        self.date = date
        self.workoutDayId = workoutDayId
        self.workoutDayName = workoutDayName
        self.durationMinutes = durationMinutes
        self.totalVolume = totalVolume
        self.notes = notes
        self.completedSets = completedSets
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMMM, HH:mm"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return "\(hours) год \(minutes) хв"
        }
        return "\(minutes) хв"
    }

    var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1f т", totalVolume / 1000)
        }
        return "\(Int(totalVolume)) кг"
    }
}

// MARK: - Completed Set

@Model
final class CompletedSet {
    var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    var rir: Int
    var isCompleted: Bool
    var completedAt: Date?

    @Relationship(inverse: \WorkoutLog.completedSets)
    var workoutLog: WorkoutLog?

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        setNumber: Int,
        weightKg: Double = 0,
        reps: Int = 0,
        rir: Int = 2,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
        self.isCompleted = isCompleted
    }

    var volume: Double {
        weightKg * Double(reps)
    }
}

// MARK: - AI Workout Recommendation

@Model
final class WorkoutRecommendation {
    var id: UUID
    var date: Date
    var workoutLogId: UUID?
    var readinessAssessment: String
    var overallAdvice: String
    var motivationalNote: String
    var progressionAdviceJson: String // JSON array

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        workoutLogId: UUID? = nil,
        readinessAssessment: String = "",
        overallAdvice: String = "",
        motivationalNote: String = "",
        progressionAdviceJson: String = "[]"
    ) {
        self.id = id
        self.date = date
        self.workoutLogId = workoutLogId
        self.readinessAssessment = readinessAssessment
        self.overallAdvice = overallAdvice
        self.motivationalNote = motivationalNote
        self.progressionAdviceJson = progressionAdviceJson
    }

    var progressionAdvice: [ProgressionAdvice] {
        guard let data = progressionAdviceJson.data(using: .utf8),
              let advice = try? JSONDecoder().decode([ProgressionAdvice].self, from: data) else {
            return []
        }
        return advice
    }
}

struct ProgressionAdvice: Codable {
    let exerciseName: String
    let currentWeight: Double
    let recommendedWeight: Double
    let reason: String
}

// MARK: - Workout Decision Log (for AI learning)

@Model
final class WorkoutDecisionLog {
    var id: UUID
    var date: Date
    var aiSuggestionType: String       // "heavy", "moderate", "light", "rest", "cardio"
    var aiSuggestionText: String       // Full AI suggestion text
    var userChoice: String             // "follow" or "ignore"
    var originalWorkoutName: String    // What was planned
    var actualWorkoutType: String?     // What actually happened: "full", "light", "rest", "cardio", nil
    var recoveryScore: Int?            // Recovery score at time of decision
    var notes: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        aiSuggestionType: String,
        aiSuggestionText: String,
        userChoice: String,
        originalWorkoutName: String,
        actualWorkoutType: String? = nil,
        recoveryScore: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.aiSuggestionType = aiSuggestionType
        self.aiSuggestionText = aiSuggestionText
        self.userChoice = userChoice
        self.originalWorkoutName = originalWorkoutName
        self.actualWorkoutType = actualWorkoutType
        self.recoveryScore = recoveryScore
        self.notes = notes
    }

    /// User followed AI advice
    static func followed(
        aiType: String,
        aiText: String,
        originalWorkout: String,
        actualType: String,
        recoveryScore: Int?
    ) -> WorkoutDecisionLog {
        WorkoutDecisionLog(
            aiSuggestionType: aiType,
            aiSuggestionText: aiText,
            userChoice: "follow",
            originalWorkoutName: originalWorkout,
            actualWorkoutType: actualType,
            recoveryScore: recoveryScore
        )
    }

    /// User ignored AI advice and kept original plan
    static func ignored(
        aiType: String,
        aiText: String,
        originalWorkout: String,
        recoveryScore: Int?
    ) -> WorkoutDecisionLog {
        WorkoutDecisionLog(
            aiSuggestionType: aiType,
            aiSuggestionText: aiText,
            userChoice: "ignore",
            originalWorkoutName: originalWorkout,
            actualWorkoutType: "full",
            recoveryScore: recoveryScore
        )
    }
}
