//
//  FitifyApp.swift
//  Fitify
//
//  Created by Юрій on 3/4/26.
//

import SwiftUI
import SwiftData

@main
struct FitifyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var coordinator = AppDataCoordinator()
    @State private var notificationService = NotificationService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AIInsight.self,
            UserProfile.self,
            WorkoutProgram.self,
            WorkoutDay.self,
            Exercise.self,
            WorkoutLog.self,
            CompletedSet.self,
            WorkoutRecommendation.self,
            SubjectiveFeedback.self,
            CachedCoachMessage.self,
            CoachState.self,
            CachedHealthHistory.self,
            WorkoutDecisionLog.self,
            BodyWeightLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(coordinator)
                    .environment(notificationService)
                    .task {
                        await coordinator.preloadAll()
                        await notificationService.checkAuthorizationStatus()
                    }
            } else {
                OnboardingView {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
                .environment(notificationService)
                .task {
                    await notificationService.requestPermission()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
