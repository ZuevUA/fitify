//
//  WorkoutProgramEditorView.swift
//  Fitify
//
//  Edit existing workout program - days and exercises
//

import SwiftUI
import SwiftData

struct WorkoutProgramEditorView: View {
    @Bindable var program: WorkoutProgram
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showExercisePicker = false
    @State private var selectedDayIndex: Int? = nil
    @State private var showAddDay = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Program name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Назва програми")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Назва", text: $program.name)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Workout days
                        ForEach(Array(program.workoutDays.enumerated()), id: \.element.id) { index, day in
                            EditorDayCard(
                                day: day,
                                onAddExercise: {
                                    selectedDayIndex = index
                                    showExercisePicker = true
                                },
                                onDeleteExercise: { exerciseIndex in
                                    deleteExercise(dayIndex: index, exerciseIndex: exerciseIndex)
                                },
                                onDeleteDay: {
                                    deleteDay(at: index)
                                }
                            )
                        }

                        // Add day button
                        Button {
                            showAddDay = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Додати тренувальний день")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(white: 0.08))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Редагувати програму")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрити") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { template in
                    addExercise(template: template)
                }
            }
            .sheet(isPresented: $showAddDay) {
                AddDaySheet { dayName in
                    addNewDay(name: dayName)
                }
            }
        }
    }

    private func addExercise(template: ExerciseTemplate) {
        guard let dayIndex = selectedDayIndex,
              dayIndex < program.workoutDays.count else { return }

        let day = program.workoutDays[dayIndex]
        let exercise = Exercise(
            name: template.name,
            nameEn: template.nameEn,
            sets: template.defaultSets,
            repsMin: template.defaultRepsMin,
            repsMax: template.defaultRepsMax,
            rir: template.defaultRir,
            restSeconds: template.defaultRestSeconds,
            notes: template.notes,
            muscleGroup: template.muscleGroup.rawValue,
            exerciseType: template.type.rawValue,
            orderIndex: day.exercises.count
        )

        day.exercises.append(exercise)
        modelContext.insert(exercise)
        try? modelContext.save()
    }

    private func deleteExercise(dayIndex: Int, exerciseIndex: Int) {
        guard dayIndex < program.workoutDays.count else { return }
        let day = program.workoutDays[dayIndex]
        guard exerciseIndex < day.exercises.count else { return }

        let exercise = day.exercises[exerciseIndex]
        day.exercises.remove(at: exerciseIndex)
        modelContext.delete(exercise)
        try? modelContext.save()
    }

    private func deleteDay(at index: Int) {
        guard index < program.workoutDays.count else { return }
        let day = program.workoutDays[index]

        // Delete all exercises in day
        for exercise in day.exercises {
            modelContext.delete(exercise)
        }

        program.workoutDays.remove(at: index)
        modelContext.delete(day)

        // Update weekly schedule
        updateWeeklySchedule()
        try? modelContext.save()
    }

    private func addNewDay(name: String) {
        let day = WorkoutDay(
            dayName: name,
            focus: "",
            orderIndex: program.workoutDays.count
        )

        program.workoutDays.append(day)
        modelContext.insert(day)

        // Update weekly schedule
        updateWeeklySchedule()
        try? modelContext.save()
    }

    private func updateWeeklySchedule() {
        program.weeklySchedule = program.workoutDays.map { $0.dayName }
    }
}

// MARK: - Editor Day Card

struct EditorDayCard: View {
    @Bindable var day: WorkoutDay
    let onAddExercise: () -> Void
    let onDeleteExercise: (Int) -> Void
    let onDeleteDay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                TextField("Назва дня", text: $day.dayName)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDeleteDay) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            // Focus (auto-generated from exercises)
            if !day.focus.isEmpty {
                Text(day.focus)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Exercises list
            if day.exercises.isEmpty {
                Text("Додай вправи до цього дня")
                    .font(.subheadline)
                    .foregroundColor(Color(white: 0.5))
            } else {
                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { index, exercise in
                    EditorExerciseRow(
                        exercise: exercise,
                        onDelete: { onDeleteExercise(index) }
                    )
                }
            }

            // Add exercise button
            Button(action: onAddExercise) {
                Label("Додати вправу", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Editor Exercise Row

struct EditorExerciseRow: View {
    @Bindable var exercise: Exercise
    let onDelete: () -> Void

    @State private var showEditor = false

    var body: some View {
        Button {
            showEditor = true
        } label: {
            HStack {
                Circle()
                    .fill(muscleColor(exercise.muscleGroup))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.9))
                    Text("\(exercise.sets) × \(exercise.repsMin)-\(exercise.repsMax) · RIR \(exercise.rir)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(white: 0.3))
                        .font(.system(size: 18))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditor) {
            ExerciseEditorSheet(exercise: exercise)
        }
    }

    func muscleColor(_ group: String) -> Color {
        switch group.lowercased() {
        case "груди", "chest": return .red
        case "спина", "back": return .blue
        case "плечі", "shoulders": return .yellow
        case "біцепс", "biceps": return .orange
        case "трицепс", "triceps": return .purple
        case "ноги", "legs": return .green
        case "сідниці", "glutes": return .pink
        case "прес", "abs": return .cyan
        case "ікри", "calves": return .teal
        default: return .gray
        }
    }
}

// MARK: - Exercise Editor Sheet

struct ExerciseEditorSheet: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Exercise name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Назва вправи")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Назва", text: $exercise.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                        }

                        // Sets
                        HStack {
                            Text("Підходів")
                                .foregroundColor(.white)
                            Spacer()
                            Stepper("\(exercise.sets)", value: $exercise.sets, in: 1...10)
                                .labelsHidden()
                            Text("\(exercise.sets)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)

                        // Reps range
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Повторень (мін)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Stepper("\(exercise.repsMin)", value: $exercise.repsMin, in: 1...50)
                                    .labelsHidden()
                            }

                            Spacer()

                            Text("\(exercise.repsMin) - \(exercise.repsMax)")
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Повторень (макс)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Stepper("\(exercise.repsMax)", value: $exercise.repsMax, in: 1...50)
                                    .labelsHidden()
                            }
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)

                        // RIR
                        HStack {
                            Text("RIR (запас)")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("RIR", selection: $exercise.rir) {
                                ForEach(0...5, id: \.self) { rir in
                                    Text("\(rir)").tag(rir)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)

                        // Rest time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Відпочинок (секунди)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Slider(
                                    value: Binding(
                                        get: { Double(exercise.restSeconds) },
                                        set: { exercise.restSeconds = Int($0) }
                                    ),
                                    in: 30...300,
                                    step: 15
                                )
                                Text("\(exercise.restSeconds) сек")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 80)
                            }
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Нотатки")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Додаткові нотатки...", text: $exercise.notes)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    let day = WorkoutDay(dayName: "Push Day", focus: "Груди, Плечі")
    let program = WorkoutProgram(
        name: "Test Program",
        splitType: "PPL",
        workoutDays: [day]
    )

    return WorkoutProgramEditorView(program: program)
        .modelContainer(for: [WorkoutProgram.self])
}
