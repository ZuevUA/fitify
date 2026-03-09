//
//  MainTabView.swift
//  Fitify
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @Environment(AppDataCoordinator.self) private var coordinator

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Головна (Dashboard)
            DashboardView(viewModel: coordinator.dashboard)
                .tabItem {
                    Label("Головна", systemImage: "house.fill")
                }
                .tag(AppTab.dashboard)

            // 2. Тренування
            WorkoutContainerView()
                .tabItem {
                    Label("Тренування", systemImage: "dumbbell.fill")
                }
                .tag(AppTab.workout)

            // 3. Прогрес
            ProgressView()
                .tabItem {
                    Label("Прогрес", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.progress)

            // 4. Коуч
            CoachView(viewModel: coordinator.coach)
                .tabItem {
                    Label("Коуч", systemImage: "brain.head.profile")
                }
                .tag(AppTab.coach)

            // 5. Здоров'я (combines Activity, Sleep, Insights)
            HealthHubView()
                .tabItem {
                    Label("Здоров'я", systemImage: "heart.fill")
                }
                .tag(AppTab.health)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - App Tab Enum

enum AppTab: Hashable {
    case dashboard
    case workout
    case progress
    case coach
    case health
}

#Preview {
    MainTabView()
        .environment(AppDataCoordinator())
}
