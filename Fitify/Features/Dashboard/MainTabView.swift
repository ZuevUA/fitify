//
//  MainTabView.swift
//  Fitify
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(AppDataCoordinator.self) private var coordinator

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: coordinator.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "heart.text.square.fill")
                }
                .tag(0)

            CoachView(viewModel: coordinator.coach)
                .tabItem {
                    Label("Коуч", systemImage: "brain.head.profile")
                }
                .tag(1)

            WorkoutContainerView()
                .tabItem {
                    Label("Тренування", systemImage: "dumbbell.fill")
                }
                .tag(2)

            SleepView(viewModel: coordinator.sleep)
                .tabItem {
                    Label("Сон", systemImage: "bed.double.fill")
                }
                .tag(3)

            ActivityView(viewModel: coordinator.activity)
                .tabItem {
                    Label("Активність", systemImage: "figure.run")
                }
                .tag(4)

            ProgressView()
                .tabItem {
                    Label("Прогрес", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(5)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .environment(AppDataCoordinator())
}
