//
//  WorkoutWelcomeView.swift
//  Fitify
//
//  Welcome screen for new users - choose how to start
//

import SwiftUI
import SwiftData

struct WorkoutWelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showProgramPicker = false
    @State private var showOnboarding = false
    @State private var showCustomBuilder = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo / Header
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    Text("Журнал тренувань")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Обери як хочеш почати")
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    // Option 1 - Ready Nippard Program
                    Button {
                        showProgramPicker = true
                    } label: {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "list.bullet.clipboard.fill")
                                        .foregroundColor(.blue)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Обрати готову програму")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("5 програм Джефа Ніпарда")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(white: 0.08))
                        .cornerRadius(16)
                    }

                    // Option 2 - AI Personal Program (onboarding)
                    Button {
                        showOnboarding = true
                    } label: {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI підбере програму")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Відповідай на питання — отримай план")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(white: 0.08))
                        .cornerRadius(16)
                    }

                    // Option 3 - Custom Program Builder
                    Button {
                        showCustomBuilder = true
                    } label: {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.green)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Почати з нуля")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Створи власну програму вручну")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(white: 0.08))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .sheet(isPresented: $showProgramPicker) {
            ProgramPickerView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            WorkoutOnboardingView {
                showOnboarding = false
            }
        }
        .fullScreenCover(isPresented: $showCustomBuilder) {
            CustomProgramBuilderView()
        }
    }
}

#Preview {
    WorkoutWelcomeView()
        .modelContainer(for: [WorkoutProgram.self])
}
