//
//  CustomProgramBuilderView.swift
//  Fitify
//
//  Custom program builder - create your own workout program from scratch
//

import SwiftUI
import SwiftData

struct CustomProgramBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var programName: String = "Моя програма"
    @State private var days: [CustomDayData] = []
    @State private var showAddDay = false
    @State private var selectedDayForExercise: Int? = nil
    @State private var showExercisePicker = false

    struct CustomDayData: Identifiable {
        let id = UUID()
        var name: String
        var exercises: [ExerciseTemplate] = []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if days.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Додай тренувальні дні")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Наприклад: Push Day, Pull Day, Leg Day")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("+ Додати день") { showAddDay = true }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(25)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Program name
                            TextField("Назва програми", text: $programName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(white: 0.08))
                                .cornerRadius(12)
                                .padding(.horizontal)

                            // Training days
                            ForEach(days.indices, id: \.self) { dayIndex in
                                CustomDayCard(
                                    day: $days[dayIndex],
                                    onAddExercise: {
                                        selectedDayForExercise = dayIndex
                                        showExercisePicker = true
                                    },
                                    onDeleteExercise: { exerciseIndex in
                                        days[dayIndex].exercises.remove(at: exerciseIndex)
                                    },
                                    onDelete: { days.remove(at: dayIndex) }
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
            }
            .navigationTitle("Нова програма")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        saveProgram()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(days.isEmpty ? .gray : .white)
                    .disabled(days.isEmpty)
                }
            }
            .sheet(isPresented: $showAddDay) {
                AddDaySheet { dayName in
                    days.append(CustomDayData(name: dayName))
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    if let idx = selectedDayForExercise {
                        days[idx].exercises.append(exercise)
                    }
                }
            }
        }
    }

    func saveProgram() {
        // Delete any existing programs first (only one active program)
        let descriptor = FetchDescriptor<WorkoutProgram>()
        if let existing = try? modelContext.fetch(descriptor) {
            for p in existing {
                modelContext.delete(p)
            }
        }

        let program = WorkoutProgram(
            name: programName,
            splitType: "custom",
            weeklySchedule: days.map { $0.name },
            startDate: Date(),
            isActive: true
        )

        for (i, dayData) in days.enumerated() {
            let muscleGroups = dayData.exercises.map { $0.muscleGroup.rawValue }.unique()
            let day = WorkoutDay(
                dayName: dayData.name,
                focus: muscleGroups.joined(separator: ", "),
                orderIndex: i + 1
            )

            for (exIdx, exTemplate) in dayData.exercises.enumerated() {
                let ex = Exercise(
                    name: exTemplate.name,
                    nameEn: exTemplate.nameEn,
                    sets: exTemplate.defaultSets,
                    repsMin: exTemplate.defaultRepsMin,
                    repsMax: exTemplate.defaultRepsMax,
                    rir: exTemplate.defaultRir,
                    restSeconds: exTemplate.defaultRestSeconds,
                    notes: exTemplate.notes,
                    muscleGroup: exTemplate.muscleGroup.rawValue,
                    exerciseType: exTemplate.type.rawValue,
                    orderIndex: exIdx
                )
                day.exercises.append(ex)
                modelContext.insert(ex)
            }

            program.workoutDays.append(day)
            modelContext.insert(day)
        }

        modelContext.insert(program)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Custom Day Card

struct CustomDayCard: View {
    @Binding var day: CustomProgramBuilderView.CustomDayData
    let onAddExercise: () -> Void
    let onDeleteExercise: (Int) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Назва дня", text: $day.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            if day.exercises.isEmpty {
                Text("Натисни + щоб додати вправи")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(day.exercises.indices, id: \.self) { idx in
                    let ex = day.exercises[idx]
                    HStack {
                        Circle()
                            .fill(muscleColor(ex.muscleGroup))
                            .frame(width: 8, height: 8)
                        Text(ex.name)
                            .font(.subheadline)
                            .foregroundColor(Color(white: 0.8))
                        Spacer()
                        Text("\(ex.defaultSets)×\(ex.defaultRepsMin)-\(ex.defaultRepsMax)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button {
                            onDeleteExercise(idx)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(white: 0.3))
                                .font(.system(size: 16))
                        }
                    }
                }
            }

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

    func muscleColor(_ group: ExMuscleGroup) -> Color {
        switch group {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .yellow
        case .biceps: return .orange
        case .triceps: return .purple
        case .legs: return .green
        case .glutes: return .pink
        case .abs: return .cyan
        case .calves: return .teal
        case .forearms: return .brown
        }
    }
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (ExerciseTemplate) -> Void

    @State private var search = ""
    @State private var selectedMuscle: ExMuscleGroup? = nil
    @State private var showCreateExercise = false
    @State private var customExercises: [ExerciseTemplate] = []

    var allExercises: [ExerciseTemplate] {
        customExercises + ExerciseLibrary.all
    }

    var filtered: [ExerciseTemplate] {
        allExercises.filter { ex in
            let matchesMuscle = selectedMuscle == nil || ex.muscleGroup == selectedMuscle
            let matchesSearch = search.isEmpty ||
                ex.name.localizedCaseInsensitiveContains(search) ||
                ex.nameEn.localizedCaseInsensitiveContains(search)
            return matchesMuscle && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Пошук вправ...", text: $search)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Muscle group filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ExerciseFilterChip(
                                title: "Всі",
                                isSelected: selectedMuscle == nil
                            ) { selectedMuscle = nil }

                            ForEach(ExMuscleGroup.allCases, id: \.self) { muscle in
                                ExerciseFilterChip(
                                    title: muscle.rawValue,
                                    isSelected: selectedMuscle == muscle
                                ) { selectedMuscle = muscle }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // Exercise list
                    List(filtered) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(exercise.muscleGroup.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(white: 0.15))
                                        .cornerRadius(8)
                                }
                                HStack(spacing: 12) {
                                    Label(exercise.equipment.rawValue, systemImage: "dumbbell")
                                    Label("\(exercise.defaultSets)×\(exercise.defaultRepsMin)-\(exercise.defaultRepsMax)", systemImage: "number")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)

                                if !exercise.notes.isEmpty {
                                    Text(exercise.notes)
                                        .font(.caption2)
                                        .foregroundColor(Color(white: 0.5))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(white: 0.06))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Вибір вправи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрити") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateExercise = true
                    } label: {
                        Label("Нова вправа", systemImage: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showCreateExercise) {
                CreateCustomExerciseView { newExercise in
                    customExercises.insert(newExercise, at: 0)
                    saveCustomExercises()
                }
            }
            .onAppear {
                loadCustomExercises()
            }
        }
    }

    private func saveCustomExercises() {
        let data = customExercises.map { ex in
            CustomExerciseData(
                name: ex.name,
                nameEn: ex.nameEn,
                muscleGroup: ex.muscleGroup.rawValue,
                type: ex.type.rawValue,
                equipment: ex.equipment.rawValue,
                defaultSets: ex.defaultSets,
                defaultRepsMin: ex.defaultRepsMin,
                defaultRepsMax: ex.defaultRepsMax,
                defaultRir: ex.defaultRir,
                defaultRestSeconds: ex.defaultRestSeconds,
                notes: ex.notes
            )
        }
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "customExercises")
        }
    }

    private func loadCustomExercises() {
        guard let data = UserDefaults.standard.data(forKey: "customExercises"),
              let decoded = try? JSONDecoder().decode([CustomExerciseData].self, from: data) else {
            return
        }
        customExercises = decoded.compactMap { data in
            guard let muscle = ExMuscleGroup(rawValue: data.muscleGroup),
                  let type = ExType(rawValue: data.type),
                  let equipment = ExEquipment(rawValue: data.equipment) else {
                return nil
            }
            return ExerciseTemplate(
                name: data.name,
                nameEn: data.nameEn,
                muscleGroup: muscle,
                type: type,
                equipment: equipment,
                defaultSets: data.defaultSets,
                defaultRepsMin: data.defaultRepsMin,
                defaultRepsMax: data.defaultRepsMax,
                defaultRir: data.defaultRir,
                defaultRestSeconds: data.defaultRestSeconds,
                notes: data.notes
            )
        }
    }
}

// MARK: - Custom Exercise Data (for persistence)

struct CustomExerciseData: Codable {
    let name: String
    let nameEn: String
    let muscleGroup: String
    let type: String
    let equipment: String
    let defaultSets: Int
    let defaultRepsMin: Int
    let defaultRepsMax: Int
    let defaultRir: Int
    let defaultRestSeconds: Int
    let notes: String
}

// MARK: - Create Custom Exercise View

struct CreateCustomExerciseView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (ExerciseTemplate) -> Void

    @State private var name = ""
    @State private var selectedMuscle: ExMuscleGroup = .chest
    @State private var selectedEquipment: ExEquipment = .barbell
    @State private var selectedType: ExType = .compound
    @State private var sets = 3
    @State private var repsMin = 8
    @State private var repsMax = 12
    @State private var rir = 2
    @State private var restSeconds = 120
    @State private var notes = ""

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Назва вправи") {
                    TextField("Наприклад: Жим гантелей", text: $name)
                }

                Section("М'язова група") {
                    Picker("М'яз", selection: $selectedMuscle) {
                        ForEach(ExMuscleGroup.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                Section("Тип та обладнання") {
                    Picker("Тип", selection: $selectedType) {
                        Text("Базова").tag(ExType.compound)
                        Text("Ізоляція").tag(ExType.isolation)
                    }
                    .pickerStyle(.segmented)

                    Picker("Обладнання", selection: $selectedEquipment) {
                        ForEach(ExEquipment.allCases, id: \.self) { e in
                            Text(e.rawValue).tag(e)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                Section("Підходи та повторення") {
                    Stepper("Підходи: \(sets)", value: $sets, in: 1...8)
                    Stepper("Мін. повт: \(repsMin)", value: $repsMin, in: 1...50)
                    Stepper("Макс. повт: \(repsMax)", value: $repsMax, in: 1...50)
                    Stepper("RIR: \(rir)", value: $rir, in: 0...5)
                    Stepper("Відпочинок: \(restSeconds)с",
                            value: $restSeconds, in: 30...300, step: 15)
                }

                Section("Нотатки (опціонально)") {
                    TextField("Техніка, поради...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .foregroundColor(.white)
            .navigationTitle("Нова вправа")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        let template = ExerciseTemplate(
                            name: name,
                            nameEn: name,
                            muscleGroup: selectedMuscle,
                            type: selectedType,
                            equipment: selectedEquipment,
                            defaultSets: sets,
                            defaultRepsMin: repsMin,
                            defaultRepsMax: repsMax,
                            defaultRir: rir,
                            defaultRestSeconds: restSeconds,
                            notes: notes
                        )
                        onSave(template)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(isValid ? .white : .gray)
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct ExerciseFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.white : Color(white: 0.15))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(20)
        }
    }
}

// MARK: - Add Day Sheet

struct AddDaySheet: View {
    @Environment(\.dismiss) var dismiss
    let onAdd: (String) -> Void
    @State private var name = ""

    let suggestions = [
        "Push Day", "Pull Day", "Leg Day",
        "Upper Body", "Lower Body", "Full Body",
        "Груди та трицепс", "Спина та біцепс"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Назва дня (напр. Push Day)", text: $name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Text("Або обери готову назву:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(suggestions, id: \.self) { s in
                            Button(s) {
                                name = s
                            }
                            .font(.subheadline)
                            .foregroundColor(name == s ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(name == s ? Color.white : Color(white: 0.12))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Новий день")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Додати") {
                        onAdd(name.isEmpty ? "Тренування" : name)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CustomProgramBuilderView()
        .modelContainer(for: [WorkoutProgram.self])
}
