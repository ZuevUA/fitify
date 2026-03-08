//
//  WorkoutTabView.swift
//  Fitify
//
//  Main entry point for workout tab - routes to appropriate view
//

import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Query private var programs: [WorkoutProgram]
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if programs.isEmpty {
                WorkoutWelcomeView()
            } else {
                WorkoutJournalView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WorkoutTabView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutLog.self])
}
