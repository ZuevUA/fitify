//
//  CoachView.swift
//  Fitify
//

import SwiftUI
import SwiftData

struct CoachView: View {
    @Bindable var viewModel: CoachViewModel
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if viewModel.isThinking {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isThinking) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                Divider()

                // Input Area
                InputArea(
                    text: $viewModel.inputText,
                    isInputFocused: $isInputFocused,
                    isSending: viewModel.isSendingMessage,
                    onSend: {
                        Task { await viewModel.sendMessage() }
                    },
                    onVoice: {
                        viewModel.showVoiceInput = true
                    }
                )
            }
            .navigationTitle("AI Коуч")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.clearHistory()
                        } label: {
                            Label("Очистити історію", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showVoiceInput) {
            VoiceInputSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            Task {
                await viewModel.checkAndSendMorningBriefing()
            }
        }
        .alert("Помилка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if viewModel.isThinking {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message type badge for special messages
                if message.type != .text {
                    MessageTypeBadge(type: message.type)
                }

                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            switch message.type {
            case .anomalyAlert:
                return .red.opacity(0.2)
            case .morningBriefing, .readinessReport:
                return .purple.opacity(0.2)
            case .workoutSuggestion:
                return .green.opacity(0.2)
            default:
                return Color(.systemGray5)
            }
        }
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

// MARK: - Message Type Badge

struct MessageTypeBadge: View {
    let type: CoachMessage.MessageType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch type {
        case .morningBriefing: return "sun.max.fill"
        case .readinessReport: return "heart.text.square.fill"
        case .workoutSuggestion: return "dumbbell.fill"
        case .anomalyAlert: return "exclamationmark.triangle.fill"
        case .weeklyReport: return "chart.bar.fill"
        case .subjectiveFeedback: return "person.fill.questionmark"
        case .text: return "text.bubble.fill"
        }
    }

    private var title: String {
        switch type {
        case .morningBriefing: return "Ранковий брифінг"
        case .readinessReport: return "Готовність"
        case .workoutSuggestion: return "Тренування"
        case .anomalyAlert: return "Увага"
        case .weeklyReport: return "Тижневий звіт"
        case .subjectiveFeedback: return "Самопочуття"
        case .text: return ""
        }
    }

    private var color: Color {
        switch type {
        case .morningBriefing: return .orange
        case .readinessReport: return .purple
        case .workoutSuggestion: return .green
        case .anomalyAlert: return .red
        case .weeklyReport: return .blue
        case .subjectiveFeedback: return .cyan
        case .text: return .gray
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationOffset = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset == index ? -4 : 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}

// MARK: - Input Area

struct InputArea: View {
    @Binding var text: String
    @FocusState.Binding var isInputFocused: Bool
    let isSending: Bool
    let onSend: () -> Void
    let onVoice: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Voice button
            Button(action: onVoice) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }

            // Text field
            TextField("Як ти себе почуваєш?", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)

            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
}

// MARK: - Voice Input Sheet

struct VoiceInputSheet: View {
    @Bindable var viewModel: CoachViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Transcript
                Text(viewModel.voiceInput.transcript.isEmpty ? "Говоріть..." : viewModel.voiceInput.transcript)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(viewModel.voiceInput.transcript.isEmpty ? .secondary : .primary)

                Spacer()

                // Recording indicator
                ZStack {
                    Circle()
                        .fill(viewModel.voiceInput.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(viewModel.voiceInput.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.voiceInput.isRecording)

                    Button {
                        viewModel.voiceInput.toggleRecording()
                    } label: {
                        Image(systemName: viewModel.voiceInput.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(viewModel.voiceInput.isRecording ? Color.red : Color.blue)
                            .clipShape(Circle())
                    }
                }

                Text(viewModel.voiceInput.isRecording ? "Натисніть, щоб зупинити" : "Натисніть, щоб говорити")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Error message
                if let error = viewModel.voiceInput.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Голосове введення")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        viewModel.voiceInput.stopRecording()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        viewModel.voiceInput.stopRecording()
                        viewModel.handleVoiceInput()
                        dismiss()
                    }
                    .disabled(viewModel.voiceInput.transcript.isEmpty)
                }
            }
            .onAppear {
                Task {
                    await viewModel.voiceInput.requestAuthorization()
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    CoachView(viewModel: CoachViewModel())
        .modelContainer(for: [CachedCoachMessage.self, SubjectiveFeedback.self, CoachState.self])
}
