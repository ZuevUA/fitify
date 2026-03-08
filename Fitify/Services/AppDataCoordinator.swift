//
//  AppDataCoordinator.swift
//  Fitify
//

import Foundation

@Observable
final class AppDataCoordinator {
    let dashboard = DashboardViewModel()
    let sleep = SleepViewModel()
    let activity = ActivityViewModel()
    let insights = InsightsViewModel()
    let coach = CoachViewModel()

    var isPreloading = false

    func preloadAll() async {
        guard !isPreloading else { return }
        isPreloading = true
        defer { isPreloading = false }

        // Load all data in parallel at startup
        async let d: () = dashboard.loadData()
        async let s: () = sleep.loadData()
        async let a: () = activity.loadData()

        // Insights loads synchronously
        insights.loadInsights()

        // Wait for async loads to complete
        _ = await (d, s, a)
    }
}
