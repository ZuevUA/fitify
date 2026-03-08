//
//  WorkoutContainerView.swift
//  Fitify
//
//  Routes to WorkoutTabView - simplified entry point
//

import SwiftUI
import SwiftData

struct WorkoutContainerView: View {
    var body: some View {
        WorkoutTabView()
    }
}

#Preview {
    WorkoutContainerView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutLog.self])
}
