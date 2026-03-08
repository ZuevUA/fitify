//
//  AIWorkoutAdjustmentViews.swift
//  Fitify
//

import SwiftUI

// MARK: - Adjusted Workout Banner

struct AdjustedWorkoutBanner: View {
    let originalWorkout: WorkoutDay
    let aiSuggestion: TodayPlan
    let onAccept: () -> Void
    let onKeepOriginal: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)

                Text("Віктор рекомендує")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Intensity indicator
                Text(intensityLabel)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(intensityColor)
                    .clipShape(Capsule())
            }

            // Original plan strikethrough
            HStack {
                Text("Заплановано:")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))

                Text(originalWorkout.dayName)
                    .font(.caption)
                    .strikethrough()
                    .foregroundColor(Color(white: 0.5))
            }

            // AI Suggestion
            Text(aiSuggestion.suggestion)
                .font(.subheadline)
                .foregroundColor(Color(white: 0.8))
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)

            // Alternative if tired
            if let alternative = aiSuggestion.alternativeIfTired {
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz")
                        .font(.caption2)
                    Text("Якщо втомлений: \(alternative)")
                        .font(.caption)
                }
                .foregroundColor(Color(white: 0.6))
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onKeepOriginal) {
                    Text("Дотримуватись плану")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color(white: 0.12))
                        .cornerRadius(20)
                }

                Button(action: onAccept) {
                    HStack(spacing: 6) {
                        Image(systemName: acceptIcon)
                            .font(.caption)
                        Text("Прийняти пораду")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.4), lineWidth: 1)
        )
    }

    private var intensityLabel: String {
        switch aiSuggestion.type {
        case "light": return "Легке"
        case "rest": return "Відпочинок"
        case "cardio": return "Кардіо"
        default: return aiSuggestion.type.capitalized
        }
    }

    private var intensityColor: Color {
        switch aiSuggestion.type {
        case "light": return .orange
        case "rest": return .red
        case "cardio": return .blue
        default: return .gray
        }
    }

    private var acceptIcon: String {
        switch aiSuggestion.type {
        case "light": return "flame"
        case "rest": return "bed.double.fill"
        case "cardio": return "figure.walk"
        default: return "checkmark"
        }
    }
}

// MARK: - Rest Day Recovery View

struct RestDayRecoveryView: View {
    let aiSuggestion: String
    let onDismiss: () -> Void

    private let suggestions = [
        ("figure.walk", "20-30 хв прогулянка", "Легке кардіо прискорює відновлення"),
        ("figure.flexibility", "Розтяжка 15 хв", "Фокус на м'язах минулого тренування"),
        ("drop.fill", "Гідратація", "2-3л води + електроліти"),
        ("bed.double.fill", "Сон 8+ год", "Найважливіший інструмент відновлення")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "battery.100.bolt")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                    }

                    Text("День відновлення")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Твоє тіло потребує відпочинку")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.6))
                }
                .padding(.top, 20)

                // AI Reason
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("Чому Віктор рекомендує відпочинок:")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }

                    Text(aiSuggestion)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.08))
                .cornerRadius(12)

                // Recovery suggestions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Що можна зробити сьогодні:")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(suggestions, id: \.0) { icon, title, description in
                        RecoverySuggestionRow(
                            icon: icon,
                            title: title,
                            description: description
                        )
                    }
                }
                .padding()
                .background(Color(white: 0.05))
                .cornerRadius(16)

                // Motivation
                VStack(spacing: 12) {
                    Text("Пам'ятай")
                        .font(.caption.bold())
                        .foregroundColor(Color(white: 0.5))

                    Text("М'язи ростуть під час відпочинку, а не під час тренування. Відпочинок — це частина прогресу.")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.8))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

                // Done button
                Button(action: onDismiss) {
                    Text("Зрозуміло")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color.black)
    }
}

struct RecoverySuggestionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.6))
            }

            Spacer()
        }
    }
}

// MARK: - Cardio Suggestion View

struct CardioSuggestionView: View {
    let aiSuggestion: String
    let onComplete: () -> Void
    let onSkip: () -> Void

    private let cardioOptions = [
        ("figure.walk", "Прогулянка", "20-30 хв", "Найпростіший варіант активного відновлення"),
        ("figure.outdoor.cycle", "Велосипед", "20-30 хв", "Легкий темп, без горок"),
        ("figure.pool.swim", "Плавання", "20-30 хв", "Чудово для суглобів і відновлення"),
        ("figure.elliptical", "Еліптик", "20 хв", "Низький вплив на суглоби")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }

                    Text("Легке кардіо")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Активне відновлення")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.6))
                }
                .padding(.top, 20)

                // AI Reason
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("Порада Віктора:")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }

                    Text(aiSuggestion)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.08))
                .cornerRadius(12)

                // Cardio options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Обери варіант кардіо:")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(cardioOptions, id: \.0) { icon, title, duration, description in
                        CardioOptionRow(
                            icon: icon,
                            title: title,
                            duration: duration,
                            description: description
                        )
                    }
                }
                .padding()
                .background(Color(white: 0.05))
                .cornerRadius(16)

                // Heart rate zone
                VStack(spacing: 8) {
                    Text("Цільова зона ЧСС")
                        .font(.caption.bold())
                        .foregroundColor(Color(white: 0.5))

                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.green)
                        Text("Zone 2: 60-70% max HR")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }

                    Text("Розмовний темп — можеш говорити повними реченнями")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.6))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onSkip) {
                        Text("Пропустити")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(12)
                    }

                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Виконано")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color.black)
    }
}

struct CardioOptionRow: View {
    let icon: String
    let title: String
    let duration: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.6))
            }

            Spacer()
        }
    }
}

// MARK: - Light Workout Badge

struct LightWorkoutBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.caption2)
            Text("Легке тренування")
                .font(.caption.bold())
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Adjusted Workout Banner") {
    VStack {
        AdjustedWorkoutBanner(
            originalWorkout: WorkoutDay(
                dayName: "Push A",
                focus: "Груди, Плечі, Трицепс"
            ),
            aiSuggestion: TodayPlan(
                type: "light",
                suggestion: "Твій HRV сьогодні на 15% нижче норми. Рекомендую легке тренування — ті самі вправи, але менше підходів і нижча вага.",
                alternativeIfTired: "Якщо відчуваєш втому — краще 20 хв легкого кардіо"
            ),
            onAccept: {},
            onKeepOriginal: {}
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Rest Day View") {
    RestDayRecoveryView(
        aiSuggestion: "Твій Recovery Score 45%, що значно нижче норми. HRV знизився на 20% за останні 3 дні. Це ознаки накопиченої втоми. Сьогодні відпочинок допоможе уникнути перетренованості.",
        onDismiss: {}
    )
}

#Preview("Cardio View") {
    CardioSuggestionView(
        aiSuggestion: "Сьогодні не найкращий день для силового тренування, але легке кардіо допоможе прискорити відновлення. 20-30 хвилин Zone 2 кардіо покращить кровообіг і прискорить видалення метаболітів.",
        onComplete: {},
        onSkip: {}
    )
}
