//
//  CoachMessage.swift
//  Fitify
//

import Foundation
import SwiftData

// MARK: - Coach Message

struct CoachMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let type: MessageType

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        type: MessageType = .text
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.type = type
    }

    enum MessageRole: String, Codable {
        case user
        case assistant
    }

    enum MessageType: String, Codable {
        case text
        case readinessReport
        case workoutSuggestion
        case anomalyAlert
        case weeklyReport
        case subjectiveFeedback
        case morningBriefing
    }

    // MARK: - Convenience Initializers

    static func user(_ content: String) -> CoachMessage {
        CoachMessage(role: .user, content: content, type: .text)
    }

    static func assistant(_ content: String, type: MessageType = .text) -> CoachMessage {
        CoachMessage(role: .assistant, content: content, type: type)
    }

    static func morningBriefing(_ content: String) -> CoachMessage {
        CoachMessage(role: .assistant, content: content, type: .morningBriefing)
    }

    static func morningBriefing(_ briefing: MorningBriefing) -> CoachMessage {
        CoachMessage(role: .assistant, content: briefing.formattedText, type: .morningBriefing)
    }

    static func fromCoachResponse(_ response: CoachResponse) -> CoachMessage {
        CoachMessage(role: .assistant, content: response.message, type: .text)
    }

    static func anomalyAlert(_ content: String) -> CoachMessage {
        CoachMessage(role: .assistant, content: content, type: .anomalyAlert)
    }
}

// MARK: - Subjective Feedback (SwiftData Model)

@Model
final class SubjectiveFeedback {
    var id: UUID
    var date: Date
    var text: String
    var sentiment: String      // positive / negative / neutral
    var tags: [String]         // ["втома", "ноги", "сон"]
    var relatedMessageId: UUID?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        text: String,
        sentiment: String = "neutral",
        tags: [String] = [],
        relatedMessageId: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.sentiment = sentiment
        self.tags = tags
        self.relatedMessageId = relatedMessageId
    }
}

// MARK: - Cached Messages (SwiftData Model)

@Model
final class CachedCoachMessage {
    var id: UUID
    var role: String
    var content: String
    var timestamp: Date
    var type: String

    init(from message: CoachMessage) {
        self.id = message.id
        self.role = message.role.rawValue
        self.content = message.content
        self.timestamp = message.timestamp
        self.type = message.type.rawValue
    }

    func toCoachMessage() -> CoachMessage {
        CoachMessage(
            id: id,
            role: CoachMessage.MessageRole(rawValue: role) ?? .assistant,
            content: content,
            timestamp: timestamp,
            type: CoachMessage.MessageType(rawValue: type) ?? .text
        )
    }
}

// MARK: - Last Briefing Date (for once-per-day check)

@Model
final class CoachState {
    var lastBriefingDate: Date?
    var lastUpdated: Date

    init(lastBriefingDate: Date? = nil) {
        self.lastBriefingDate = lastBriefingDate
        self.lastUpdated = Date()
    }

    var needsMorningBriefing: Bool {
        guard let lastDate = lastBriefingDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }
}
