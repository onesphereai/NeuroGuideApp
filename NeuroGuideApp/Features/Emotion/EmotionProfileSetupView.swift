//
//  EmotionProfileSetupView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import SwiftUI

/// Setup view for emotion expression profile
/// Neurodivergent-aware questions about how child expresses emotions
struct EmotionProfileSetupView: View {
    let childID: UUID
    let childName: String

    @StateObject private var profileManager = EmotionProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var profile: EmotionExpressionProfile
    @State private var isSaving = false
    @State private var currentPage = 0

    init(childID: UUID, childName: String) {
        self.childID = childID
        self.childName = childName

        // Initialize with empty profile
        _profile = State(initialValue: EmotionExpressionProfile(childID: childID))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                // Content
                TabView(selection: $currentPage) {
                    generalPatternsPage.tag(0)
                    joyExpressionsPage.tag(1)
                    calmExpressionsPage.tag(2)
                    frustrationExpressionsPage.tag(3)
                    overwhelmExpressionsPage.tag(4)
                    focusedExpressionsPage.tag(5)
                    dysregulatedExpressionsPage.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Expression Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                // Load existing profile if available
                if let existing = try? await profileManager.getProfile(childID: childID) {
                    profile = existing
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(currentPage + 1), total: 7)
                .progressViewStyle(.linear)

            Text("Step \(currentPage + 1) of 7")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Page 0: General Patterns

    private var generalPatternsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pageHeader(
                    title: "About \(childName)'s Communication",
                    description: "Help us understand how \(childName) typically communicates. There are no 'right' answers - every child is unique!"
                )

                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $profile.hasFlatAffect) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Has flat affect")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Facial expressions may be subtle or less visible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Toggle(isOn: $profile.usesEcholalia) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Uses echolalia or scripting")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Repeats words, phrases, or scripts from media")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Toggle(isOn: $profile.stimsWhenHappy) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stims when happy or excited")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Flapping, bouncing, vocalizing, spinning, etc.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Toggle(isOn: $profile.stimsWhenDistressed) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stims when overwhelmed or distressed")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Rocking, pacing, hand movements, etc.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Toggle(isOn: $profile.hasAlexithymia) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Has alexithymia")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Difficulty identifying or describing emotions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Toggle(isOn: $profile.isNonSpeaking) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Non-speaking or minimally speaking")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("May use AAC, signs, or other communication methods")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    // MARK: - Page 1: Joy

    private var joyExpressionsPage: some View {
        expressionPage(
            emotion: .joy,
            expressions: $profile.joyExpressions,
            commonPatterns: CommonExpressionPatterns.joy
        )
    }

    // MARK: - Page 2: Calm

    private var calmExpressionsPage: some View {
        expressionPage(
            emotion: .calm,
            expressions: $profile.calmExpressions,
            commonPatterns: CommonExpressionPatterns.calm
        )
    }

    // MARK: - Page 3: Frustration

    private var frustrationExpressionsPage: some View {
        expressionPage(
            emotion: .frustration,
            expressions: $profile.frustrationExpressions,
            commonPatterns: CommonExpressionPatterns.frustration
        )
    }

    // MARK: - Page 4: Overwhelm

    private var overwhelmExpressionsPage: some View {
        expressionPage(
            emotion: .overwhelm,
            expressions: $profile.overwhelmExpressions,
            commonPatterns: CommonExpressionPatterns.overwhelm
        )
    }

    // MARK: - Page 5: Focused

    private var focusedExpressionsPage: some View {
        expressionPage(
            emotion: .focused,
            expressions: $profile.focusedExpressions,
            commonPatterns: CommonExpressionPatterns.focused
        )
    }

    // MARK: - Page 6: Dysregulated

    private var dysregulatedExpressionsPage: some View {
        expressionPage(
            emotion: .dysregulated,
            expressions: $profile.dysregulatedExpressions,
            commonPatterns: CommonExpressionPatterns.dysregulated
        )
    }

    // MARK: - Expression Page Template

    private func expressionPage(
        emotion: EmotionLabel,
        expressions: Binding<[String]>,
        commonPatterns: [String]
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pageHeader(
                    title: "How \(childName) Shows \(emotion.displayName)",
                    description: "Select common patterns or add your own descriptions. You can skip this if you're not sure."
                )

                // Common patterns
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common Patterns")
                        .font(.headline)

                    ForEach(commonPatterns, id: \.self) { pattern in
                        commonPatternButton(pattern: pattern, expressions: expressions)
                    }
                }

                // Custom expressions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Expressions")
                        .font(.headline)

                    if expressions.wrappedValue.isEmpty {
                        Text("No custom expressions added yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    } else {
                        ForEach(expressions.wrappedValue, id: \.self) { expression in
                            customExpressionRow(expression: expression, expressions: expressions)
                        }
                    }

                    addExpressionButton(expressions: expressions)
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func pageHeader(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private func commonPatternButton(pattern: String, expressions: Binding<[String]>) -> some View {
        let isSelected = expressions.wrappedValue.contains(pattern)

        return Button(action: {
            if isSelected {
                expressions.wrappedValue.removeAll { $0 == pattern }
            } else {
                expressions.wrappedValue.append(pattern)
            }
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)

                Text(pattern)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func customExpressionRow(expression: String, expressions: Binding<[String]>) -> some View {
        HStack {
            Text(expression)
                .font(.body)

            Spacer()

            Button(action: {
                expressions.wrappedValue.removeAll { $0 == expression }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    @State private var showingAddExpression = false
    @State private var newExpression = ""

    private func addExpressionButton(expressions: Binding<[String]>) -> some View {
        Button(action: {
            showingAddExpression = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Custom Expression")
            }
            .font(.body)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingAddExpression) {
            addExpressionSheet(expressions: expressions)
        }
    }

    private func addExpressionSheet(expressions: Binding<[String]>) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Describe how they show this emotion...", text: $newExpression, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding()

                Spacer()
            }
            .navigationTitle("Add Expression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newExpression = ""
                        showingAddExpression = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !newExpression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            expressions.wrappedValue.append(newExpression)
                            newExpression = ""
                            showingAddExpression = false
                        }
                    }
                    .disabled(newExpression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button(action: {
                    withAnimation {
                        currentPage -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }

            if currentPage < 6 {
                Button(action: {
                    withAnimation {
                        currentPage += 1
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                Button(action: {
                    Task {
                        await saveProfile()
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isSaving ? "Saving..." : "Save Profile")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
            }
        }
        .padding()
    }

    // MARK: - Save

    private func saveProfile() async {
        isSaving = true

        do {
            try await profileManager.updateProfile(childID: childID, profile: profile)
            dismiss()
        } catch {
            print("❌ Failed to save emotion profile: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    EmotionProfileSetupView(
        childID: UUID(),
        childName: "Alex"
    )
}
