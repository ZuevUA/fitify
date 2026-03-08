//
//  ActivityViewModel.swift
//  Fitify
//

import Foundation

@Observable
final class ActivityViewModel {
    private let healthKitService = HealthKitService.shared

    // Activity data
    var steps: Int = 0
    var stepsGoal: Int = 10000
    var calories: Int = 0
    var caloriesGoal: Int = 600
    var exerciseMinutes: Int = 0
    var exerciseGoal: Int = 60
    var standHours: Int = 0
    var standGoal: Int = 12

    // Weekly data
    var weeklySteps: [Int] = []
    var weekDays: [String] = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]

    // Recent workouts
    var recentWorkouts: [Workout] = []

    var isLoading = false
    var hasLoadedOnce = false
    var errorMessage: String?

    // MARK: - Progress Values

    var moveProgress: Double {
        guard caloriesGoal > 0 else { return 0 }
        return min(Double(calories) / Double(caloriesGoal), 1.0)
    }

    var exerciseProgress: Double {
        guard exerciseGoal > 0 else { return 0 }
        return min(Double(exerciseMinutes) / Double(exerciseGoal), 1.0)
    }

    var standProgress: Double {
        guard standGoal > 0 else { return 0 }
        return min(Double(standHours) / Double(standGoal), 1.0)
    }

    var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(steps) / Double(stepsGoal), 1.0)
    }

    var stepsRemaining: Int {
        max(0, stepsGoal - steps)
    }

    // MARK: - Formatted Values

    var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    var formattedCalories: String {
        return "\(calories)"
    }

    var formattedExercise: String {
        return "\(exerciseMinutes)"
    }

    var formattedStand: String {
        return "\(standHours)"
    }

    var formattedStepsRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: stepsRemaining)) ?? "\(stepsRemaining)"
    }

    // MARK: - Actions

    func loadData() async {
        guard !isLoading else { return }
        guard !hasLoadedOnce else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard healthKitService.isHealthKitAvailable else {
                useMockData()
                hasLoadedOnce = true
                return
            }

            if !healthKitService.isAuthorized {
                try await healthKitService.requestPermissions()
            }

            // Fetch all activity data in parallel
            async let stepsData = healthKitService.fetchStepCount()
            async let caloriesData = healthKitService.fetchActiveCalories()
            async let weeklyData = healthKitService.fetchWeeklyRecoveryData()

            let fetchedSteps = try await stepsData
            let fetchedCalories = try await caloriesData
            let weekly = try await weeklyData

            // Update current day data
            steps = fetchedSteps
            calories = Int(fetchedCalories)

            // Update weekly steps
            weeklySteps = weekly.map { $0.steps ?? 0 }

            // Estimate exercise minutes based on steps (rough approximation)
            // Assuming 100 steps per minute of walking
            exerciseMinutes = min(steps / 100, exerciseGoal)

            // Estimate stand hours based on time of day
            let hour = Calendar.current.component(.hour, from: Date())
            standHours = min(max(hour - 6, 0), standGoal) // Assuming awake from 6 AM

            // Load mock workouts (HealthKit workout fetching would require additional implementation)
            loadMockWorkouts()

        } catch {
            errorMessage = error.localizedDescription
            useMockData()
        }

        hasLoadedOnce = true
    }

    func refresh() async {
        hasLoadedOnce = false
        await loadData()
    }

    private func loadMockWorkouts() {
        recentWorkouts = [
            Workout(name: "Ранкова пробіжка", type: "running", duration: 32, calories: 287, date: Date().addingTimeInterval(-3600)),
            Workout(name: "Силове тренування", type: "strength", duration: 45, calories: 198, date: Date().addingTimeInterval(-86400)),
            Workout(name: "Велосипед", type: "cycling", duration: 28, calories: 156, date: Date().addingTimeInterval(-172800))
        ]
    }

    func useMockData() {
        steps = 7234
        calories = 487
        exerciseMinutes = 35
        standHours = 9
        weeklySteps = [8234, 6521, 9102, 7845, 5632, 10234, 7234]
        loadMockWorkouts()
    }
}

// MARK: - Workout Model

struct Workout: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let duration: Int // minutes
    let calories: Int
    let date: Date

    var iconName: String {
        switch type {
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "strength": return "dumbbell.fill"
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.mind.and.body"
        default: return "figure.mixed.cardio"
        }
    }

    var formattedDuration: String {
        return "\(duration) хв"
    }

    var formattedCalories: String {
        return "\(calories) ккал"
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
