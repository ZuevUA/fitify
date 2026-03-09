//
//  NotificationService.swift
//  Fitify
//

import Foundation
import UserNotifications

@Observable
class NotificationService {
    var isAuthorized = false

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Morning Briefing (daily at 8:00)

    func scheduleMorningBriefing(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morning_briefing"])
        guard enabled && isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Ранковий брифінг"
        content.body = "Віктор чекає з аналізом твого відновлення"
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "morning_briefing",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Workout Reminder

    func scheduleWorkoutReminder(
        workoutName: String,
        date: Date,
        minutesBefore: Int = 30
    ) {
        let center = UNUserNotificationCenter.current()
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Час тренуватись!"
        content.body = "\(workoutName) починається через \(minutesBefore) хвилин"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(
            byAdding: .minute, value: -minutesBefore, to: date
        ) else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "workout_\(Int(date.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelWorkoutReminder(for date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["workout_\(Int(date.timeIntervalSince1970))"]
        )
    }

    // MARK: - Streak Reminder (daily at 19:00 if not worked out)

    func scheduleStreakReminder(currentStreak: Int, enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
        guard enabled && isAuthorized else { return }

        let content = UNMutableNotificationContent()
        if currentStreak > 0 {
            content.title = "Не переривай серію!"
            content.body = "У тебе \(currentStreak) днів поспіль. Сьогодні ще не тренувався"
        } else {
            content.title = "Час повернутись!"
            content.body = "Віктор чекає на тебе в додатку"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Clear All Notifications

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
