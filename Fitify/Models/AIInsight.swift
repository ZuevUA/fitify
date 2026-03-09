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
        case .recovery: return "Відновлення"
        case .sleep: return "Сон"
        case .activity: return "Активність"
        case .stress: return "Стрес"
        case .illness: return "Здоров'я"
        case .general: return "Загальне"
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
                title: "Відмінне відновлення",
                content: "Твій HRV зріс на 15% за останній тиждень. Твій організм добре адаптується до поточного навантаження.",
                category: .recovery,
                priority: 1
            ),
            AIInsight(
                title: "Виявлено патерн сну",
                content: "Ти лягаєш спати на 45 хвилин пізніше у вихідні. Стабільний графік сну покращить якість відновлення.",
                category: .sleep,
                priority: 2
            ),
            AIInsight(
                title: "Серія досягнутих цілей",
                content: "Ти досяг цілі кроків 5 днів поспіль! Можеш збільшити денну ціль на 500 кроків.",
                category: .activity,
                priority: 3
            )
        ]
    }
}
