//
//  LoadingAndError.swift
//  Fitify
//

import SwiftUI

// MARK: - Loading State Enum

enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.5)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(white: 0.12))
            .cornerRadius(20)
        }
    }
}

// MARK: - Card Loading View

struct CardLoadingView: View {
    var body: some View {
        HStack {
            ProgressView().tint(.gray)
            Text("Завантаження...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: - Skeleton View (Shimmer)

struct SkeletonView: View {
    @State private var phase: CGFloat = 0
    let height: CGFloat
    let cornerRadius: CGFloat

    init(height: CGFloat = 60, cornerRadius: CGFloat = 10) {
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.12),
                        Color(white: 0.18),
                        Color(white: 0.12)
                    ],
                    startPoint: .init(x: phase - 1, y: 0),
                    endPoint: .init(x: phase, y: 0)
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let retryAction: (() -> Void)?
    @Binding var isVisible: Bool

    init(message: String, retryAction: (() -> Void)? = nil, isVisible: Binding<Bool>) {
        self.message = message
        self.retryAction = retryAction
        self._isVisible = isVisible
    }

    var body: some View {
        if isVisible {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation { isVisible = false }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                if let retry = retryAction {
                    Button("Спробувати знову") { retry() }
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(Color(white: 0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            if let title = actionTitle, let action = action {
                Button(title, action: action)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Internet View

struct NoInternetView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("Немає з'єднання")
                .font(.headline)
                .foregroundColor(.white)
            Text("Перевір підключення до інтернету\nта спробуй ще раз")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("Повторити", action: retryAction)
                .font(.subheadline.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Dashboard Skeleton

struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Recovery card skeleton
            SkeletonView(height: 200, cornerRadius: 24)
                .padding(.horizontal)

            // Metrics grid skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonView(height: 100, cornerRadius: 16)
                }
            }
            .padding(.horizontal)

            // Weekly trend skeleton
            SkeletonView(height: 140, cornerRadius: 20)
                .padding(.horizontal)

            // Insight card skeleton
            SkeletonView(height: 120, cornerRadius: 20)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}

// MARK: - Health Hub Skeleton

struct HealthHubSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Stats row
            HStack(spacing: 12) {
                SkeletonView(height: 100, cornerRadius: 16)
                SkeletonView(height: 100, cornerRadius: 16)
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                SkeletonView(height: 100, cornerRadius: 16)
                SkeletonView(height: 100, cornerRadius: 16)
            }
            .padding(.horizontal)

            // Weekly chart skeleton
            SkeletonView(height: 140, cornerRadius: 16)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}

// MARK: - Previews

#Preview("Skeleton") {
    ZStack {
        Color.black.ignoresSafeArea()
        DashboardSkeletonView()
    }
}

#Preview("Error Banner") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            ErrorBanner(
                message: "Не вдалось завантажити дані",
                retryAction: { },
                isVisible: .constant(true)
            )
            .padding()
            Spacer()
        }
    }
}

#Preview("Empty State") {
    ZStack {
        Color.black.ignoresSafeArea()
        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "Немає даних",
            subtitle: "Почни тренуватись щоб бачити свій прогрес",
            actionTitle: "Почати тренування",
            action: { }
        )
    }
}

#Preview("No Internet") {
    ZStack {
        Color.black.ignoresSafeArea()
        NoInternetView { }
    }
}

#Preview("Loading Overlay") {
    ZStack {
        Color.black.ignoresSafeArea()
        Text("Background content")
            .foregroundColor(.white)
        LoadingOverlay(message: "Генерація інсайту...")
    }
}
