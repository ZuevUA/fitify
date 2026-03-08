//
//  ProfileView.swift
//  Fitify
//

import SwiftUI
import SwiftData

// MARK: - ProfileView

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    @Query private var programs: [WorkoutProgram]
    @Query private var bodyWeightLogs: [BodyWeightLog]

    @State private var showEditProfile = false
    @State private var showOnboarding = false

    var profile: UserProfile? { profiles.first }

    // MARK: - Statistics

    var totalWorkouts: Int { workoutLogs.count }

    var totalTonnage: Double {
        workoutLogs.flatMap { $0.completedSets }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    var currentStreak: Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        let logDates = Set(workoutLogs.map {
            Calendar.current.startOfDay(for: $0.date)
        })

        while logDates.contains(checkDate) ||
              logDates.contains(Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!) {
            if logDates.contains(checkDate) { streak += 1 }
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
            if streak > 365 { break }
        }
        return streak
    }

    var totalTrainingDays: Int {
        Set(workoutLogs.map {
            Calendar.current.startOfDay(for: $0.date)
        }).count
    }

    var currentWeight: Double? { bodyWeightLogs.last?.weightKg }

    var memberSince: Date {
        workoutLogs.map { $0.date }.min() ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Hero Section
                        VStack(spacing: 12) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)

                                Text(initials)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Button {
                                    showEditProfile = true
                                } label: {
                                    Circle()
                                        .fill(Color(white: 0.2))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Image(systemName: "pencil")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                .offset(x: 30, y: 30)
                            )

                            // Name and Goal
                            VStack(spacing: 4) {
                                Text(profile?.name ?? "Спортсмен")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                HStack(spacing: 6) {
                                    if let profile = profile {
                                        GoalBadge(goal: profile.workoutGoal)
                                        LevelBadge(level: profile.experienceLevel)
                                    }
                                }

                                Text("З нами з \(memberSince.formatted(.dateTime.month(.wide).year()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 8)

                        // MARK: - Main Statistics
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                value: "\(totalWorkouts)",
                                label: "Тренувань",
                                icon: "dumbbell.fill",
                                color: .blue
                            )
                            StatCard(
                                value: "\(currentStreak)",
                                label: "Серія днів",
                                icon: "flame.fill",
                                color: currentStreak > 0 ? .orange : .gray
                            )
                            StatCard(
                                value: formatTonnage(totalTonnage),
                                label: "Загальний об'єм",
                                icon: "scalemass.fill",
                                color: .green
                            )
                            StatCard(
                                value: currentWeight != nil ? "\(String(format: "%.1f", currentWeight!)) кг" : "—",
                                label: "Поточна вага",
                                icon: "person.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)

                        // MARK: - Training Profile
                        if let profile = profile {
                            ProfileSection(title: "Профіль тренувань") {
                                ProfileRow(label: "Ціль", value: profile.workoutGoal.displayName, icon: "target")
                                ProfileRow(label: "Рівень", value: profile.experienceLevel.displayName, icon: "chart.bar.fill")
                                ProfileRow(label: "Стать", value: profile.userGender.displayName, icon: "person.fill")
                                ProfileRow(label: "Вік", value: "\(profile.age) років", icon: "birthday.cake")
                                ProfileRow(label: "Вага", value: "\(String(format: "%.1f", profile.weightKg)) кг", icon: "scalemass")
                                ProfileRow(label: "Тренувань/тиждень", value: "\(profile.trainingDaysPerWeek) дні", icon: "calendar")
                                ProfileRow(label: "Тривалість сесії", value: profile.sessionDurationMinutes == 999 ? "Необмежено" : "\(profile.sessionDurationMinutes) хв", icon: "timer")
                            }
                        }

                        // MARK: - Active Program
                        if let activeProgram = programs.first(where: { $0.isActive }) {
                            ProfileSection(title: "Активна програма") {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activeProgram.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(activeProgram.workoutDays.count) тренувальних днів")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("Почато: \(activeProgram.startDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // MARK: - Achievements
                        ProfileSection(title: "Досягнення") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(achievements, id: \.title) { achievement in
                                        AchievementBadgeView(achievement: achievement)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // MARK: - Settings
                        ProfileSection(title: "Налаштування") {
                            SettingsRow(
                                icon: "bell.fill",
                                label: "Сповіщення",
                                color: .orange
                            ) {
                                Toggle("", isOn: .constant(true))
                                    .tint(.orange)
                            }

                            SettingsRow(
                                icon: "heart.fill",
                                label: "Apple Health",
                                color: .red
                            ) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }

                            SettingsRow(
                                icon: "moon.fill",
                                label: "Одиниці виміру",
                                color: .purple
                            ) {
                                Text("кг / км")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        // MARK: - Other
                        ProfileSection(title: "Інше") {
                            Button {
                                showOnboarding = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                        .frame(width: 28)
                                    Text("Пройти онбординг знову")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(.vertical, 4)
                            }

                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.gray)
                                    .frame(width: 28)
                                Text("Версія")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Профіль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: profile)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                WorkoutOnboardingView {
                    showOnboarding = false
                }
            }
        }
    }

    var initials: String {
        guard let name = profile?.name, !name.isEmpty else { return "Ю" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }

    func formatTonnage(_ kg: Double) -> String {
        if kg >= 1000 { return "\(String(format: "%.1f", kg/1000))т" }
        return "\(Int(kg))кг"
    }

    var achievements: [Achievement] {
        var list: [Achievement] = []
        if totalWorkouts >= 1 { list.append(.init(emoji: "🎯", title: "Перший крок", subtitle: "1 тренування")) }
        if totalWorkouts >= 10 { list.append(.init(emoji: "🔥", title: "На розігріві", subtitle: "10 тренувань")) }
        if totalWorkouts >= 50 { list.append(.init(emoji: "💪", title: "Залізна воля", subtitle: "50 тренувань")) }
        if currentStreak >= 7 { list.append(.init(emoji: "📅", title: "Тижнева серія", subtitle: "7 днів поспіль")) }
        if totalTonnage >= 10000 { list.append(.init(emoji: "🏋️", title: "Десять тонн", subtitle: "10т загального об'єму")) }
        if list.isEmpty { list.append(.init(emoji: "🌱", title: "Початок шляху", subtitle: "Поверхай тренуватись!")) }
        return list
    }
}

// MARK: - Achievement Model

struct Achievement {
    let emoji: String
    let title: String
    let subtitle: String
}

// MARK: - Supporting Views

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(white: 0.07))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

struct ProfileRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            Text(label)
                .foregroundColor(Color(white: 0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .padding(.vertical, 10)
        .overlay(
            Divider()
                .background(Color(white: 0.12))
                .padding(.leading, 32),
            alignment: .bottom
        )
    }
}

struct SettingsRow<Accessory: View>: View {
    let icon: String
    let label: String
    let color: Color
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 7)
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                )
            Text(label)
                .foregroundColor(.white)
            Spacer()
            accessory
        }
        .padding(.vertical, 10)
        .overlay(
            Divider().background(Color(white: 0.12)).padding(.leading, 40),
            alignment: .bottom
        )
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.emoji)
                .font(.system(size: 32))
            Text(achievement.title)
                .font(.caption.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(achievement.subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90)
        .padding(.vertical, 12)
        .background(Color(white: 0.1))
        .cornerRadius(14)
    }
}

struct GoalBadge: View {
    let goal: WorkoutGoal

    var body: some View {
        Text(goal.displayName)
            .font(.caption.bold())
            .foregroundColor(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(20)
    }
}

struct LevelBadge: View {
    let level: ExperienceLevel

    var body: some View {
        Text(level.displayName)
            .font(.caption.bold())
            .foregroundColor(.purple)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.15))
            .cornerRadius(20)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let profile: UserProfile?

    @State private var name: String = ""
    @State private var weightKg: Double = 70
    @State private var age: Int = 25
    @State private var trainingDays: Int = 3
    @State private var sessionDuration: Int = 60

    var body: some View {
        NavigationStack {
            Form {
                Section("Особисті дані") {
                    HStack {
                        Text("Ім'я")
                        Spacer()
                        TextField("Ім'я", text: $name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    Stepper("Вік: \(age) р.", value: $age, in: 16...80)
                    Stepper("Вага: \(String(format: "%.1f", weightKg)) кг",
                            value: $weightKg, in: 40...200, step: 0.5)
                }

                Section("Тренування") {
                    Stepper("Тренувань/тиждень: \(trainingDays)",
                            value: $trainingDays, in: 2...7)
                    Picker("Тривалість", selection: $sessionDuration) {
                        Text("30 хв").tag(30)
                        Text("45 хв").tag(45)
                        Text("60 хв").tag(60)
                        Text("Необмежено").tag(999)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Редагувати профіль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }.foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                if let p = profile {
                    name = p.name ?? ""
                    weightKg = p.weightKg
                    age = p.age
                    trainingDays = p.trainingDaysPerWeek
                    sessionDuration = p.sessionDurationMinutes
                }
            }
        }
    }

    func saveProfile() {
        if let p = profile {
            p.name = name
            p.weightKg = weightKg
            p.age = age
            p.trainingDaysPerWeek = trainingDays
            p.sessionDurationMinutes = sessionDuration
            try? modelContext.save()
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, WorkoutLog.self, WorkoutProgram.self, BodyWeightLog.self])
}
