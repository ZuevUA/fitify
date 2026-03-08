//
//  ProgramPickerView.swift
//  Fitify
//
//  Program selection view with start date picker
//

import SwiftUI
import SwiftData

struct ProgramPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProgram: NippardProgramTemplate?
    @State private var startDate: Date = Date()
    @State private var showDatePicker = false

    let programs = NippardPrograms.all

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Program list
                        ForEach(programs, id: \.id) { program in
                            ProgramCard(
                                program: program,
                                isSelected: selectedProgram?.id == program.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedProgram = program
                                }
                            }
                        }

                        // Start date selection (shows when program selected)
                        if selectedProgram != nil {
                            Divider()
                                .background(Color(white: 0.2))
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Дата початку")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                // Quick date options
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(quickDateOptions, id: \.label) { option in
                                            Button(option.label) {
                                                startDate = option.date
                                            }
                                            .font(.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Calendar.current.isDate(startDate, inSameDayAs: option.date)
                                                    ? Color.white
                                                    : Color(white: 0.15)
                                            )
                                            .foregroundColor(
                                                Calendar.current.isDate(startDate, inSameDayAs: option.date)
                                                    ? .black : .white
                                            )
                                            .cornerRadius(20)
                                        }

                                        // Custom date picker
                                        Button {
                                            showDatePicker = true
                                        } label: {
                                            Label(
                                                startDate.formatted(date: .abbreviated, time: .omitted),
                                                systemImage: "calendar"
                                            )
                                            .font(.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(white: 0.15))
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Обери програму")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрити") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Почати") {
                        if let program = selectedProgram {
                            saveAndStart(program: program)
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(selectedProgram != nil ? .white : .gray)
                    .disabled(selectedProgram == nil)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $startDate)
        }
    }

    var quickDateOptions: [(label: String, date: Date)] {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let monday = Calendar.current.nextDate(
            after: today,
            matching: DateComponents(weekday: 2),
            matchingPolicy: .nextTime
        )!
        return [
            ("Сьогодні", today),
            ("Завтра", tomorrow),
            ("Пн", monday)
        ]
    }

    private func saveAndStart(program: NippardProgramTemplate) {
        // Create UserProfile placeholder
        let profile = UserProfile(
            goal: .buildMuscle,
            experience: program.targetLevels.contains("beginner") ? .beginner :
                       program.targetLevels.contains("intermediate") ? .intermediate : .advanced,
            trainingDaysPerWeek: program.frequencyDays,
            sessionDurationMinutes: program.maxSessionMinutes
        )

        // Create WorkoutProgram from template
        let workoutProgram = NippardProgramSelector.createWorkoutProgram(from: program, profile: profile)
        workoutProgram.startDate = startDate

        modelContext.insert(workoutProgram)
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: NippardProgramTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.nameUk)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 12) {
                            Label("\(program.frequencyDays) дні/тиж", systemImage: "calendar")
                            Label("~\(program.maxSessionMinutes) хв", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    Spacer()
                    // Level badge
                    Text(levelBadge)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(8)
                }

                // Description
                Text(program.description)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))
                    .lineLimit(2)

                // Training days visualization
                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        let isTraining = program.workoutDays.contains {
                            $0.dayNumber == day && !$0.exercises.isEmpty
                        }
                        Circle()
                            .fill(isTraining ? Color.blue : Color(white: 0.2))
                            .frame(width: 8, height: 8)
                    }
                    Text(workoutDayNames)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(isSelected ? Color(white: 0.15) : Color(white: 0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    var levelBadge: String {
        if program.targetLevels.contains("beginner") {
            return "Початківець"
        } else if program.targetLevels.contains("advanced") {
            return "Просунутий"
        }
        return "Середній"
    }

    var workoutDayNames: String {
        program.workoutDays
            .filter { !$0.exercises.isEmpty }
            .map { $0.workoutType }
            .prefix(3)
            .joined(separator: " · ")
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .preferredColorScheme(.dark)
                .navigationTitle("Обери дату")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ProgramPickerView()
        .modelContainer(for: [WorkoutProgram.self])
}
