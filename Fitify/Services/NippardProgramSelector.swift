//
//  NippardProgramSelector.swift
//  Fitify
//
//  Selects the best matching Nippard program based on user profile
//

import Foundation

struct NippardProgramSelector {

    /// Selects the best matching program template based on user profile
    static func selectBestProgram(for profile: UserProfile) -> NippardProgramTemplate {
        let templates = NippardPrograms.all
        let trainingDays = profile.trainingDaysPerWeek
        let experience = profile.experience
        let sessionDuration = profile.sessionDurationMinutes
        let goal = profile.goal

        // Score each template
        var scores: [(template: NippardProgramTemplate, score: Int)] = []

        for template in templates {
            var score = 0

            // 1. Frequency match (most important) - up to 40 points
            let frequencyDiff = abs(template.frequencyDays - trainingDays)
            switch frequencyDiff {
            case 0: score += 40
            case 1: score += 25
            case 2: score += 10
            default: score += 0
            }

            // 2. Experience level match - up to 30 points
            if template.targetLevels.contains(experience) {
                score += 30
            } else {
                // Partial credit if close
                let experienceLevels = ["beginner", "intermediate", "advanced"]
                if let templateIdx = template.targetLevels.first.flatMap({ experienceLevels.firstIndex(of: $0) }),
                   let userIdx = experienceLevels.firstIndex(of: experience) {
                    let diff = abs(templateIdx - userIdx)
                    if diff == 1 {
                        score += 15
                    }
                }
            }

            // 3. Session duration match - up to 20 points
            // sessionDuration == 0 means "as long as needed"
            if sessionDuration == 0 {
                score += 20 // Any duration is fine
            } else if sessionDuration >= template.maxSessionMinutes {
                score += 20
            } else if sessionDuration >= template.maxSessionMinutes - 15 {
                score += 15
            } else if sessionDuration >= template.maxSessionMinutes - 30 {
                score += 10
            }

            // 4. Goal match - up to 10 points
            if template.goal == goal {
                score += 10
            } else if (template.goal == "buildMuscle" && (goal == "loseFat" || goal == "recomp")) ||
                      (template.goal == "strength" && goal == "buildMuscle") {
                score += 5 // Related goals
            }

            scores.append((template, score))
        }

        // Sort by score descending and return best match
        scores.sort { $0.score > $1.score }

        print("🎯 Program selection scores:")
        for (template, score) in scores {
            print("   - \(template.name): \(score) points")
        }

        return scores.first?.template ?? NippardPrograms.fundamentals3Day
    }

    /// Converts a template to a WorkoutProgram model
    static func createWorkoutProgram(from template: NippardProgramTemplate, profile: UserProfile) -> WorkoutProgram {
        var workoutDays: [WorkoutDay] = []
        var workoutDayIndex = 0

        // Create workout days only for training days (not rest days)
        for dayTemplate in template.workoutDays {
            guard !dayTemplate.exercises.isEmpty else { continue }

            var exercises: [Exercise] = []

            for (exIndex, exTemplate) in dayTemplate.exercises.enumerated() {
                let exercise = Exercise(
                    name: exTemplate.name,
                    nameEn: exTemplate.nameEn,
                    sets: exTemplate.sets,
                    repsMin: exTemplate.repsMin,
                    repsMax: exTemplate.repsMax,
                    rir: exTemplate.rir,
                    restSeconds: exTemplate.restSeconds,
                    notes: exTemplate.notes,
                    progressionNote: "",
                    muscleGroup: exTemplate.muscleGroup,
                    exerciseType: isCompoundExercise(exTemplate.nameEn) ? "compound" : "isolation",
                    orderIndex: exIndex
                )
                exercises.append(exercise)
            }

            let day = WorkoutDay(
                dayName: "День \(workoutDayIndex + 1): \(dayTemplate.workoutType)",
                focus: dayTemplate.workoutType,
                estimatedDurationMinutes: calculateDuration(exercises: dayTemplate.exercises),
                orderIndex: workoutDayIndex,
                exercises: exercises
            )
            workoutDays.append(day)
            workoutDayIndex += 1
        }

        // Create weekly schedule
        var weeklySchedule: [String] = []
        var workoutIdx = 0
        for dayTemplate in template.workoutDays {
            if dayTemplate.exercises.isEmpty {
                weeklySchedule.append("Відпочинок")
            } else {
                weeklySchedule.append(dayTemplate.workoutType)
                workoutIdx += 1
            }
        }

        let program = WorkoutProgram(
            name: template.nameUk,
            splitType: determineSplitType(template: template),
            weeklyVolumeSummary: generateVolumeSummary(template: template, profile: profile),
            progressionStrategy: generateProgressionStrategy(profile: profile),
            deloadProtocol: "Кожні 4-6 тижнів: знизити вагу на 40%, зберегти підходи та повторення",
            aiNotes: template.description,
            weeklySchedule: weeklySchedule,
            workoutDays: workoutDays,
            isActive: true
        )

        print("📦 Created WorkoutProgram: \(program.name)")
        print("   Days: \(program.workoutDays.count)")
        print("   Split: \(program.splitType)")

        return program
    }

    // MARK: - Helper Methods

    private static func isCompoundExercise(_ nameEn: String) -> Bool {
        let compoundExercises = [
            "squat", "deadlift", "bench press", "press", "row",
            "pull-up", "pullup", "dip", "lunge", "split squat"
        ]
        let lowerName = nameEn.lowercased()
        return compoundExercises.contains { lowerName.contains($0) }
    }

    private static func calculateDuration(exercises: [NippardExerciseTemplate]) -> Int {
        var totalSeconds = 0

        for ex in exercises {
            // Time per set: ~45 sec working + rest
            let timePerSet = 45 + ex.restSeconds
            totalSeconds += ex.sets * timePerSet
        }

        // Add warm-up time
        totalSeconds += 5 * 60 // 5 minutes

        return totalSeconds / 60
    }

    private static func determineSplitType(template: NippardProgramTemplate) -> String {
        let workoutTypes = template.workoutDays
            .filter { !$0.exercises.isEmpty }
            .map { $0.workoutType.lowercased() }

        if workoutTypes.allSatisfy({ $0.contains("full body") }) {
            return "Full Body"
        } else if workoutTypes.contains(where: { $0.contains("push") }) &&
                  workoutTypes.contains(where: { $0.contains("pull") }) {
            return "PPL"
        } else if workoutTypes.contains(where: { $0.contains("upper") }) &&
                  workoutTypes.contains(where: { $0.contains("lower") }) {
            return "Upper/Lower"
        }

        return template.frequencyDays <= 3 ? "Full Body" : "Upper/Lower"
    }

    private static func generateVolumeSummary(template: NippardProgramTemplate, profile: UserProfile) -> String {
        // Count sets per muscle group across all workout days
        var muscleVolume: [String: Int] = [:]

        for day in template.workoutDays {
            for ex in day.exercises {
                let muscle = ex.muscleGroup
                muscleVolume[muscle, default: 0] += ex.sets
            }
        }

        let sortedMuscles = muscleVolume.sorted { $0.value > $1.value }
        let top3 = sortedMuscles.prefix(3)

        let summary = top3.map { "\($0.key): \($0.value) сетів/тиждень" }.joined(separator: ", ")
        return "Тижневий об'єм: \(summary)"
    }

    private static func generateProgressionStrategy(profile: UserProfile) -> String {
        switch profile.experience {
        case "beginner":
            return "Лінійна прогресія: додавай 2.5кг щотижня на базові вправи, 1.25кг на ізоляцію"
        case "intermediate":
            return "Подвійна прогресія: спочатку досягни верхньої межі повторень, потім додай вагу"
        case "advanced":
            return "Хвильова періодизація: чергуй важкі (6-8 повт) та легкі (12-15 повт) тижні"
        default:
            return "Подвійна прогресія: спочатку повторення, потім вага"
        }
    }
}
