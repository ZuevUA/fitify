//
//  Extensions.swift
//  Fitify
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    static let recoveryGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let recoveryYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let recoveryRed = Color(red: 0.9, green: 0.3, blue: 0.3)

    static let cardBackground = Color(white: 0.12)
    static let secondaryBackground = Color(white: 0.08)

    static func recoveryColor(for score: Int) -> Color {
        switch score {
        case 0..<40:
            return .recoveryRed
        case 40..<70:
            return .recoveryYellow
        default:
            return .recoveryGreen
        }
    }

    static func riskColor(for level: RiskLevel) -> Color {
        switch level {
        case .low:
            return .recoveryGreen
        case .medium:
            return .orange
        case .high:
            return .recoveryRed
        }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func metricCardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeDescription: String {
        if isToday {
            return "Сьогодні"
        } else if isYesterday {
            return "Вчора"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "uk_UA")
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }

    var timeDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    var hoursAndMinutes: (hours: Int, minutes: Int) {
        let totalMinutes = Int(self) / 60
        return (totalMinutes / 60, totalMinutes % 60)
    }

    var formattedDuration: String {
        let (hours, minutes) = hoursAndMinutes
        if hours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Double Extensions

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    var percentageString: String {
        "\(Int(self))%"
    }
}

// MARK: - Int Extensions

extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Animation Extensions

extension Animation {
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
}

// MARK: - Gradient Extensions

extension LinearGradient {
    static let recoveryGradient = LinearGradient(
        colors: [.recoveryGreen, .recoveryGreen.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [.orange, .orange.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dangerGradient = LinearGradient(
        colors: [.recoveryRed, .recoveryRed.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
