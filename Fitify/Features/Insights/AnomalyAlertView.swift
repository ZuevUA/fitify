//
//  AnomalyAlertView.swift
//  Fitify
//

import SwiftUI

// MARK: - Single Anomaly Alert Card

struct AnomalyAlertView: View {
    let anomaly: HealthAnomaly

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with severity icon and title
            HStack(spacing: 8) {
                Image(systemName: anomaly.severityIcon)
                    .font(.title3)
                    .foregroundColor(severityColor)

                Text(anomaly.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Type badge
                Image(systemName: anomaly.typeIcon)
                    .font(.caption)
                    .foregroundColor(typeColor)
                    .padding(6)
                    .background(typeColor.opacity(0.2))
                    .clipShape(Circle())
            }

            // Description
            Text(anomaly.description)
                .font(.subheadline)
                .foregroundColor(Color(white: 0.7))

            // Trend indicator
            if !anomaly.trend.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                    Text(anomaly.trend)
                        .font(.caption)
                }
                .foregroundColor(Color(white: 0.5))
            }

            // Recommendation
            Text(anomaly.recommendation)
                .font(.subheadline.italic())
                .foregroundColor(.blue)

            // Doctor recommendation if needed
            if anomaly.shouldSeeDoctor, let note = anomaly.doctorNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "stethoscope")
                        .font(.subheadline)
                        .foregroundColor(.yellow)

                    Text(note)
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(white: 0.07))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(severityColor.opacity(0.4), lineWidth: 1)
        )
    }

    private var severityColor: Color {
        switch anomaly.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var typeColor: Color {
        switch anomaly.type {
        case .overtrained: return .orange
        case .illness: return .red
        case .sleepDebt: return .purple
        case .cardiac: return .pink
        case .positive: return .green
        }
    }
}

// MARK: - Anomaly Summary Section

struct AnomalySummarySection: View {
    let result: AnomalyDetectionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundColor(trendColor)

                Text("Тижневий аналіз здоров'я")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Week score badge
                Text("\(result.weekScore)/10")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(scoreColor)
                    .clipShape(Capsule())
            }

            // Overall trend
            HStack(spacing: 8) {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                Text(trendText)
                    .font(.subheadline)
                    .foregroundColor(trendColor)
            }

            // Positive note
            if !result.positiveNote.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(result.positiveNote)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.8))
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }

            // Anomalies list
            if !result.anomalies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Виявлені патерни:")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.5))

                    ForEach(result.anomalies) { anomaly in
                        AnomalyAlertView(anomaly: anomaly)
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.05))
        .cornerRadius(20)
    }

    private var trendColor: Color {
        switch result.overallTrend {
        case "improving": return .green
        case "declining": return .red
        default: return .blue
        }
    }

    private var trendIcon: String {
        switch result.overallTrend {
        case "improving": return "arrow.up.right"
        case "declining": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    private var trendText: String {
        switch result.overallTrend {
        case "improving": return "Показники покращуються"
        case "declining": return "Показники погіршуються"
        default: return "Показники стабільні"
        }
    }

    private var scoreColor: Color {
        switch result.weekScore {
        case 8...10: return .green
        case 5...7: return .orange
        default: return .red
        }
    }
}

// MARK: - Coach Anomaly Message View

struct CoachAnomalyMessageView: View {
    let result: AnomalyDetectionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Viktor header
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Віктор — тижневий звіт")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Divider()
                .background(Color(white: 0.3))

            // Week summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Оцінка тижня")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.5))
                    Text("\(result.weekScore)/10")
                        .font(.title2.bold())
                        .foregroundColor(scoreColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Загальний тренд")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.5))
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                        Text(trendText)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(trendColor)
                }
            }

            // Positive note
            if !result.positiveNote.isEmpty {
                Text(result.positiveNote)
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.vertical, 4)
            }

            // Critical anomalies only
            let criticalAnomalies = result.anomalies.filter { $0.severity == .high || $0.severity == .medium }
            if !criticalAnomalies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Важливо:")
                        .font(.caption.bold())
                        .foregroundColor(.orange)

                    ForEach(criticalAnomalies) { anomaly in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: anomaly.severityIcon)
                                .font(.caption)
                                .foregroundColor(anomaly.severity == .high ? .red : .orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(anomaly.title)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                Text(anomaly.recommendation)
                                    .font(.caption)
                                    .foregroundColor(Color(white: 0.7))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }

    private var trendColor: Color {
        switch result.overallTrend {
        case "improving": return .green
        case "declining": return .red
        default: return .blue
        }
    }

    private var trendIcon: String {
        switch result.overallTrend {
        case "improving": return "arrow.up.right"
        case "declining": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    private var trendText: String {
        switch result.overallTrend {
        case "improving": return "Покращення"
        case "declining": return "Спад"
        default: return "Стабільно"
        }
    }

    private var scoreColor: Color {
        switch result.weekScore {
        case 8...10: return .green
        case 5...7: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AnomalyAlertView(anomaly: HealthAnomaly(
                type: .sleepDebt,
                severity: .medium,
                title: "Накопичений недосип",
                description: "За останні 7 днів середня тривалість сну 5.8 год",
                trend: "-12% за 14 днів",
                recommendation: "Намагайся лягати на 30 хв раніше цього тижня",
                shouldSeeDoctor: false,
                doctorNote: nil
            ))

            AnomalyAlertView(anomaly: HealthAnomaly(
                type: .cardiac,
                severity: .high,
                title: "Підвищений пульс у спокої",
                description: "ЧСС спокою 78 уд/хв при нормі 62",
                trend: "+8% за 14 днів",
                recommendation: "Зменш інтенсивність тренувань",
                shouldSeeDoctor: true,
                doctorNote: "Якщо пульс не нормалізується за 5 днів — зверніться до кардіолога"
            ))

            AnomalySummarySection(result: AnomalyDetectionResult(
                anomalies: [
                    HealthAnomaly(
                        type: .positive,
                        severity: .low,
                        title: "HRV покращився",
                        description: "Варіабельність серцевого ритму зросла на 15%",
                        trend: "+15% за 14 днів",
                        recommendation: "Продовжуй в тому ж дусі!",
                        shouldSeeDoctor: false,
                        doctorNote: nil
                    )
                ],
                overallTrend: "improving",
                weekScore: 8,
                positiveNote: "Твій сон став якіснішим — більше фази глибокого сну"
            ))
        }
        .padding()
    }
    .background(Color.black)
}
