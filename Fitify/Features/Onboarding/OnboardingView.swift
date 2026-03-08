//
//  OnboardingView.swift
//  Fitify
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isRequestingPermissions = false
    @State private var permissionsGranted = false

    let onComplete: () -> Void
    private let healthKitService = HealthKitService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 60)

                // Content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    FeaturesPage()
                        .tag(1)

                    PermissionsPage(
                        isRequesting: $isRequestingPermissions,
                        permissionsGranted: $permissionsGranted,
                        onRequestPermissions: requestHealthKitPermissions
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage < 2 {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Далі")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            HStack {
                                if isRequestingPermissions {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text(permissionsGranted ? "Почати" : "Продовжити без дозволів")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(permissionsGranted ? Color.green : Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isRequestingPermissions)
                    }

                    if currentPage > 0 && currentPage < 2 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            Text("Назад")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    if currentPage == 2 && !permissionsGranted {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Пропустити")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func requestHealthKitPermissions() {
        isRequestingPermissions = true

        Task {
            do {
                try await healthKitService.requestPermissions()
                await MainActor.run {
                    permissionsGranted = true
                    isRequestingPermissions = false
                }
            } catch {
                await MainActor.run {
                    isRequestingPermissions = false
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon/logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text("Fitify")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Твій персональний AI-помічник\nдля здоров'я та відновлення")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Features Page

struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Що вміє Fitify")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "waveform.path.ecg",
                    color: .red,
                    title: "Аналіз здоров'я",
                    description: "Відстеження пульсу, HRV, сну та інших метрик"
                )

                FeatureRow(
                    icon: "brain.head.profile",
                    color: .purple,
                    title: "AI-інсайти",
                    description: "Персоналізовані рекомендації на основі твоїх даних"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    title: "Оцінка відновлення",
                    description: "Дізнайся, чи готовий твій організм до навантажень"
                )

                FeatureRow(
                    icon: "shield.checkered",
                    color: .orange,
                    title: "Раннє виявлення",
                    description: "Попередження про можливі проблеми зі здоров'ям"
                )
            }
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Permissions Page

struct PermissionsPage: View {
    @Binding var isRequesting: Bool
    @Binding var permissionsGranted: Bool
    let onRequestPermissions: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.red)
            }

            VStack(spacing: 12) {
                Text("Доступ до Health")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("Для роботи Fitify потрібен доступ до\nтвоїх даних здоров'я з Apple Health")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            // Permission items
            VStack(alignment: .leading, spacing: 16) {
                PermissionItem(icon: "heart.fill", text: "Пульс та HRV")
                PermissionItem(icon: "bed.double.fill", text: "Дані про сон")
                PermissionItem(icon: "figure.walk", text: "Кроки та активність")
                PermissionItem(icon: "thermometer.medium", text: "Температура тіла")
            }
            .padding(.horizontal, 24)

            if !permissionsGranted {
                Button {
                    onRequestPermissions()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "heart.text.square.fill")
                            Text("Надати доступ")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isRequesting)
                .padding(.horizontal, 24)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Доступ надано")
                        .foregroundStyle(.green)
                }
                .font(.headline)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct PermissionItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.red)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
