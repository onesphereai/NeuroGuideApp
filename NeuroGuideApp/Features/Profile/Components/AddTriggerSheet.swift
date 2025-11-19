//
//  AddTriggerSheet.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Modal sheet for adding triggers with predefined options
struct AddTriggerSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (Trigger) -> Void

    @State private var selectedTriggers: Set<PredefinedTrigger> = []
    @State private var customTriggerText: String = ""
    @State private var customTriggerCategory: TriggerCategory = .sensory
    @State private var showingCustomInput: Bool = false
    @FocusState private var isCustomInputFocused: Bool

    var canAdd: Bool {
        !selectedTriggers.isEmpty || (!customTriggerText.trimmingCharacters(in: .whitespaces).isEmpty && showingCustomInput)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header question
                    VStack(spacing: 8) {
                        Text("What situations make things harder for your child?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Choose from the common examples below or add your own. This helps us understand what might overwhelm your child.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)

                    // Sensory Triggers
                    TriggerCategorySection(
                        icon: "🔶",
                        heading: "Sensory",
                        subheading: "Things your child sees, hears, or feels that can feel overwhelming",
                        triggers: PredefinedTrigger.sensoryTriggers,
                        selectedTriggers: $selectedTriggers,
                        onAddCustom: {
                            customTriggerCategory = .sensory
                            showingCustomInput = true
                        }
                    )

                    // Social Triggers
                    TriggerCategorySection(
                        icon: "🔶",
                        heading: "Social",
                        subheading: "Interactions or social expectations that may be hard",
                        triggers: PredefinedTrigger.socialTriggers,
                        selectedTriggers: $selectedTriggers,
                        onAddCustom: {
                            customTriggerCategory = .social
                            showingCustomInput = true
                        }
                    )

                    // Routine Triggers
                    TriggerCategorySection(
                        icon: "🔶",
                        heading: "Routine",
                        subheading: "Transitions or changes in plans",
                        triggers: PredefinedTrigger.routineTriggers,
                        selectedTriggers: $selectedTriggers,
                        onAddCustom: {
                            customTriggerCategory = .routine
                            showingCustomInput = true
                        }
                    )

                    // Environmental Triggers
                    TriggerCategorySection(
                        icon: "🔶",
                        heading: "Environmental",
                        subheading: "Busy places, new situations",
                        triggers: PredefinedTrigger.environmentalTriggers,
                        selectedTriggers: $selectedTriggers,
                        onAddCustom: {
                            customTriggerCategory = .environmental
                            showingCustomInput = true
                        }
                    )

                    // Other / Emotional Triggers
                    TriggerCategorySection(
                        icon: "🔶",
                        heading: "Other",
                        subheading: "Anything else that affects your child",
                        triggers: PredefinedTrigger.otherTriggers,
                        selectedTriggers: $selectedTriggers,
                        onAddCustom: {
                            customTriggerCategory = .other
                            showingCustomInput = true
                        }
                    )

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Add Triggers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedTriggers.count))") {
                        addSelectedTriggers()
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomInput) {
                CustomTriggerInputSheet(
                    category: customTriggerCategory,
                    text: $customTriggerText,
                    isPresented: $showingCustomInput,
                    onAdd: { trigger in
                        onAdd(trigger)
                    }
                )
            }
        }
    }

    private func addSelectedTriggers() {
        // Add all selected predefined triggers
        for predefinedTrigger in selectedTriggers {
            let trigger = Trigger(
                description: predefinedTrigger.description,
                category: predefinedTrigger.category
            )
            onAdd(trigger)
        }

        isPresented = false
    }
}

// MARK: - Trigger Category Section

struct TriggerCategorySection: View {
    let icon: String
    let heading: String
    let subheading: String
    let triggers: [PredefinedTrigger]
    @Binding var selectedTriggers: Set<PredefinedTrigger>
    let onAddCustom: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(icon)
                        .font(.title3)

                    Text(heading)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Text(subheading)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
            .padding(.horizontal, 4)

            // Trigger options
            VStack(spacing: 10) {
                ForEach(triggers) { trigger in
                    TriggerOptionRow(
                        trigger: trigger,
                        isSelected: selectedTriggers.contains(trigger),
                        onToggle: {
                            if selectedTriggers.contains(trigger) {
                                selectedTriggers.remove(trigger)
                            } else {
                                selectedTriggers.insert(trigger)
                            }
                        }
                    )
                }

                // "Other" option
                Button(action: onAddCustom) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        Text("Other: Add your own")
                            .font(.system(size: 15))
                            .foregroundColor(.blue)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Trigger Option Row

struct TriggerOptionRow: View {
    let trigger: PredefinedTrigger
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.blue : Color.clear)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Trigger text
                Text(trigger.description)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Trigger Input Sheet

struct CustomTriggerInputSheet: View {
    let category: TriggerCategory
    @Binding var text: String
    @Binding var isPresented: Bool
    let onAdd: (Trigger) -> Void

    @FocusState private var isFocused: Bool

    var canAdd: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Add Custom Trigger")
                        .font(.headline)

                    Text("Tell us more… e.g., loud noises, hair washing, crowded places.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal)

                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    TextField("e.g., Loud noises in shopping centres", text: $text)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trigger = Trigger(
                            description: text.trimmingCharacters(in: .whitespaces),
                            category: category
                        )
                        onAdd(trigger)
                        text = ""
                        isPresented = false
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Predefined Trigger Model

struct PredefinedTrigger: Identifiable, Hashable {
    let id: UUID = UUID()
    let description: String
    let category: TriggerCategory

    // MARK: - Sensory Triggers
    static let sensoryTriggers: [PredefinedTrigger] = [
        PredefinedTrigger(description: "Loud sudden noises", category: .sensory),
        PredefinedTrigger(description: "Busy or noisy environments", category: .sensory),
        PredefinedTrigger(description: "Bright lights or flashing lights", category: .sensory),
        PredefinedTrigger(description: "Strong smells", category: .sensory),
        PredefinedTrigger(description: "Certain textures (clothing, food, surfaces)", category: .sensory),
        PredefinedTrigger(description: "Being touched unexpectedly", category: .sensory),
        PredefinedTrigger(description: "Water on face / hair washing", category: .sensory),
        PredefinedTrigger(description: "Temperature changes", category: .sensory)
    ]

    // MARK: - Social Triggers
    static let socialTriggers: [PredefinedTrigger] = [
        PredefinedTrigger(description: "Large groups", category: .social),
        PredefinedTrigger(description: "New people", category: .social),
        PredefinedTrigger(description: "Unstructured social time", category: .social),
        PredefinedTrigger(description: "Sharing or turn-taking", category: .social),
        PredefinedTrigger(description: "Being asked questions suddenly", category: .social),
        PredefinedTrigger(description: "Social expectations (eye contact, greetings)", category: .social)
    ]

    // MARK: - Routine Triggers
    static let routineTriggers: [PredefinedTrigger] = [
        PredefinedTrigger(description: "Switching activities", category: .routine),
        PredefinedTrigger(description: "Leaving the house", category: .routine),
        PredefinedTrigger(description: "Bedtime or morning routines", category: .routine),
        PredefinedTrigger(description: "Unexpected changes", category: .routine),
        PredefinedTrigger(description: "Waiting (doctor, restaurant, school pickup)", category: .routine),
        PredefinedTrigger(description: "Being rushed", category: .routine)
    ]

    // MARK: - Environmental Triggers
    static let environmentalTriggers: [PredefinedTrigger] = [
        PredefinedTrigger(description: "Crowded spaces (shopping centres, parks)", category: .environmental),
        PredefinedTrigger(description: "New places", category: .environmental),
        PredefinedTrigger(description: "School environment", category: .environmental),
        PredefinedTrigger(description: "Restaurants / supermarkets", category: .environmental),
        PredefinedTrigger(description: "Car seat or car travel", category: .environmental),
        PredefinedTrigger(description: "Public toilets", category: .environmental)
    ]

    // MARK: - Other / Emotional Triggers
    static let otherTriggers: [PredefinedTrigger] = [
        PredefinedTrigger(description: "Feeling misunderstood", category: .other),
        PredefinedTrigger(description: "Not knowing what will happen next", category: .other),
        PredefinedTrigger(description: "Hunger / tiredness", category: .other),
        PredefinedTrigger(description: "Feeling rushed", category: .other),
        PredefinedTrigger(description: "Difficult instructions", category: .other),
        PredefinedTrigger(description: "Performance pressure", category: .other)
    ]
}

// MARK: - Preview

struct AddTriggerSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddTriggerSheet(
            isPresented: .constant(true),
            onAdd: { _ in }
        )
    }
}
