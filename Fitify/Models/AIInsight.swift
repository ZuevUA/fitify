//
//  AIInsight.swift
//  Fitify
//

import Foundation
import SwiftData

@Model
final class AIInsight {
    var id: UUID
    var timestamp: Date
    var title: String
    var content: String
    var category: String
    var priority: Int
    var isRead: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        title: String,
        content: String,
        category: InsightCategory,
        priority: Int = 0,
        isRead: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.content = content
        self.category = category.rawValue
        self.priority = priority
        self.isRead = isRead
    }

    var insightCategory: InsightCategory {
        InsightCategory(rawValue: category) ?? .general
    }
}

enum InsightCategory: String, CaseIterable, Identifiable {
    case recovery
    case sleep
    case activity
    case stress
    case illness
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recovery: return "Recovery"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        case .stress: return "Stress"
        case .illness: return "Health Alert"
        case .general: return "General"
        }
    }

    var iconName: String {
        switch self {
        case .recovery: return "arrow.up.heart.fill"
        case .sleep: return "moon.fill"
        case .activity: return "figure.run"
        case .stress: return "brain.head.profile"
        case .illness: return "cross.circle.fill"
        case .general: return "sparkles"
        }
    }

    var accentColor: String {
        switch self {
        case .recovery: return "green"
        case .sleep: return "indigo"
        case .activity: return "orange"
        case .stress: return "purple"
        case .illness: return "red"
        case .general: return "blue"
        }
    }
}

extension AIInsight {
    static var mockInsights: [AIInsight] {
        [
            AIInsight(
                title: "Great Recovery",
                content: "Your HRV has improved 15% over the past week. Your body is adapting well to your current training load.",
                category: .recovery,
                priority: 1
            ),
            AIInsight(
                title: "Sleep Pattern Detected",
                content: "You've been going to bed 45 minutes later on weekends. Consistent sleep timing can improve your recovery score.",
                category: .sleep,
                priority: 2
            ),
            AIInsight(
                title: "Activity Goal Streak",
                content: "You've hit your step goal 5 days in a row! Consider increasing your daily target by 500 steps.",
                category: .activity,
                priority: 3
            )
        ]
    }
}
