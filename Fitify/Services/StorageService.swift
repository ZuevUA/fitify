//
//  StorageService.swift
//  Fitify
//

import Foundation
import SwiftData

@Observable
final class StorageService {
    static let shared = StorageService()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private init() {
        setupContainer()
    }

    private func setupContainer() {
        do {
            let schema = Schema([AIInsight.self, CachedHealthHistory.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
            if let container = modelContainer {
                modelContext = ModelContext(container)
            }
        } catch {
            print("Failed to setup SwiftData container: \(error)")
        }
    }

    // MARK: - Insights

    func saveInsight(_ insight: AIInsight) {
        guard let context = modelContext else { return }
        context.insert(insight)
        try? context.save()
    }

    func fetchInsights(limit: Int = 20) -> [AIInsight] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<AIInsight>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            var fetchDescriptor = descriptor
            fetchDescriptor.fetchLimit = limit
            return try context.fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

    func fetchLatestInsight() -> AIInsight? {
        fetchInsights(limit: 1).first
    }

    func fetchUnreadInsights() -> [AIInsight] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<AIInsight>(
            predicate: #Predicate { !$0.isRead },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    func markInsightAsRead(_ insight: AIInsight) {
        insight.isRead = true
        try? modelContext?.save()
    }

    func deleteInsight(_ insight: AIInsight) {
        modelContext?.delete(insight)
        try? modelContext?.save()
    }

    func deleteAllInsights() {
        guard let context = modelContext else { return }

        do {
            try context.delete(model: AIInsight.self)
            try context.save()
        } catch {
            print("Failed to delete all insights: \(error)")
        }
    }

    // MARK: - Statistics

    func insightsCount() -> Int {
        guard let context = modelContext else { return 0 }

        do {
            let descriptor = FetchDescriptor<AIInsight>()
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    func insightsCount(for category: InsightCategory) -> Int {
        guard let context = modelContext else { return 0 }

        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<AIInsight>(
            predicate: #Predicate { $0.category == categoryRaw }
        )

        do {
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
}
