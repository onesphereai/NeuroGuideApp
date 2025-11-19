//
//  AddStrategySheet.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Modal sheet for adding strategies with predefined options
struct AddStrategySheet: View {
    @Binding var isPresented: Bool
    let onAdd: (Strategy) -> Void

    @State private var selectedStrategies: Set<PredefinedStrategy> = []
    @State private var customStrategyText: String = ""
    @State private var customStrategyCategory: StrategyCategory = .sensory
    @State private var showingCustomInput: Bool = false
    @FocusState private var isCustomInputFocused: Bool

    var canAdd: Bool {
        !selectedStrategies.isEmpty || (!customStrategyText.trimmingCharacters(in: .whitespaces).isEmpty && showingCustomInput)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header question
                    VStack(spacing: 8) {
                        Text("What helps your child feel calm or safe when they're overwhelmed?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Choose from the examples below or add your own. This helps us suggest strategies that match your child's needs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)

                    // Sensory Input
                    StrategyCategorySection(
                        icon: "🟣",
                        heading: "Sensory Input",
                        subheading: "Activities or sensations that help your child feel grounded",
                        strategies: PredefinedStrategy.sensoryStrategies,
                        selectedStrategies: $selectedStrategies,
                        onAddCustom: {
                            customStrategyCategory = .sensory
                            showingCustomInput = true
                        }
                    )

                    // Environmental
                    StrategyCategorySection(
                        icon: "🟢",
                        heading: "Environmental",
                        subheading: "Adjusting the environment to feel calmer",
                        strategies: PredefinedStrategy.environmentalStrategies,
                        selectedStrategies: $selectedStrategies,
                        onAddCustom: {
                            customStrategyCategory = .environmental
                            showingCustomInput = true
                        }
                    )

                    // Communication
                    StrategyCategorySection(
                        icon: "🔵",
                        heading: "Communication",
                        subheading: "Tools that help your child understand or express their needs",
                        strategies: PredefinedStrategy.communicationStrategies,
                        selectedStrategies: $selectedStrategies,
                        onAddCustom: {
                            customStrategyCategory = .communication
                            showingCustomInput = true
                        }
                    )

                    // Co-Regulation
                    StrategyCategorySection(
                        icon: "🩷",
                        heading: "Co-Regulation",
                        subheading: "Things you do together to support your child",
                        strategies: PredefinedStrategy.coRegulationStrategies,
                        selectedStrategies: $selectedStrategies,
                        onAddCustom: {
                            customStrategyCategory = .coRegulation
                            showingCustomInput = true
                        }
                    )

                    // Transition Support
                    StrategyCategorySection(
                        icon: "🟠",
                        heading: "Transition Support",
                        subheading: "Helps with changing activities or routines",
                        strategies: PredefinedStrategy.transitionStrategies,
                        selectedStrategies: $selectedStrategies,
                        onAddCustom: {
                            customStrategyCategory = .transition
                            showingCustomInput = true
                        }
                    )

                    // Other
                    StrategyCategorySection(
                        icon: "⚪️",
                        heading: "Other",
                        subheading: "Any other helpful strategies",
                        strategies: PredefinedStrategy.otherStrategies,
                        selectedStrategies: $selectedStrategies,
                        onAddCustom: {
                            customStrategyCategory = .other
                            showingCustomInput = true
                        }
                    )

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Add Strategies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedStrategies.count))") {
                        addSelectedStrategies()
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomInput) {
                CustomStrategyInputSheet(
                    category: customStrategyCategory,
                    text: $customStrategyText,
                    isPresented: $showingCustomInput,
                    onAdd: { strategy in
                        onAdd(strategy)
                    }
                )
            }
        }
    }

    private func addSelectedStrategies() {
        // Add all selected predefined strategies
        for predefinedStrategy in selectedStrategies {
            let strategy = Strategy(
                description: predefinedStrategy.description,
                category: predefinedStrategy.category,
                effectivenessRating: 0.0
            )
            onAdd(strategy)
        }

        isPresented = false
    }
}

// MARK: - Strategy Category Section

struct StrategyCategorySection: View {
    let icon: String
    let heading: String
    let subheading: String
    let strategies: [PredefinedStrategy]
    @Binding var selectedStrategies: Set<PredefinedStrategy>
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

            // Strategy options
            VStack(spacing: 10) {
                ForEach(strategies) { strategy in
                    StrategyOptionRow(
                        strategy: strategy,
                        isSelected: selectedStrategies.contains(strategy),
                        onToggle: {
                            if selectedStrategies.contains(strategy) {
                                selectedStrategies.remove(strategy)
                            } else {
                                selectedStrategies.insert(strategy)
                            }
                        }
                    )
                }

                // "Add your own" option
                Button(action: onAddCustom) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        Text("Add your own")
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

// MARK: - Strategy Option Row

struct StrategyOptionRow: View {
    let strategy: PredefinedStrategy
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

                // Strategy text
                Text(strategy.description)
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

// MARK: - Custom Strategy Input Sheet

struct CustomStrategyInputSheet: View {
    let category: StrategyCategory
    @Binding var text: String
    @Binding var isPresented: Bool
    let onAdd: (Strategy) -> Void

    @FocusState private var isFocused: Bool

    var canAdd: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Add Custom Strategy")
                        .font(.headline)

                    Text("Tell us what helps… e.g., deep pressure hugs, quiet corner, visual timer.")
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

                    TextField("e.g., Deep pressure hugs", text: $text)
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
                        let strategy = Strategy(
                            description: text.trimmingCharacters(in: .whitespaces),
                            category: category,
                            effectivenessRating: 0.0
                        )
                        onAdd(strategy)
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

// MARK: - Predefined Strategy Model

struct PredefinedStrategy: Identifiable, Hashable {
    let id: UUID = UUID()
    let description: String
    let category: StrategyCategory

    // MARK: - Sensory Input Strategies
    static let sensoryStrategies: [PredefinedStrategy] = [
        PredefinedStrategy(description: "Deep pressure (tight hugs, weighted blanket)", category: .sensory),
        PredefinedStrategy(description: "Movement breaks (jumping, spinning, swinging)", category: .sensory),
        PredefinedStrategy(description: "Fidget toys or sensory items", category: .sensory),
        PredefinedStrategy(description: "Chewing gum or chewy items", category: .sensory),
        PredefinedStrategy(description: "Listening to calming music or white noise", category: .sensory),
        PredefinedStrategy(description: "Soft textures (blanket, stuffed animal)", category: .sensory),
        PredefinedStrategy(description: "Physical activity (running, climbing)", category: .sensory)
    ]

    // MARK: - Environmental Strategies
    static let environmentalStrategies: [PredefinedStrategy] = [
        PredefinedStrategy(description: "Quiet corner or safe space", category: .environmental),
        PredefinedStrategy(description: "Dimming lights or reducing brightness", category: .environmental),
        PredefinedStrategy(description: "Reducing noise levels", category: .environmental),
        PredefinedStrategy(description: "Temperature adjustment (cool/warm)", category: .environmental),
        PredefinedStrategy(description: "Removing clutter or visual distractions", category: .environmental),
        PredefinedStrategy(description: "Being in nature or outdoors", category: .environmental)
    ]

    // MARK: - Communication Strategies
    static let communicationStrategies: [PredefinedStrategy] = [
        PredefinedStrategy(description: "Visual schedule or checklist", category: .communication),
        PredefinedStrategy(description: "Emotion cards or feelings chart", category: .communication),
        PredefinedStrategy(description: "AAC device or communication app", category: .communication),
        PredefinedStrategy(description: "Choice boards", category: .communication),
        PredefinedStrategy(description: "Social stories or visual scripts", category: .communication),
        PredefinedStrategy(description: "Writing or drawing feelings", category: .communication)
    ]

    // MARK: - Co-Regulation Strategies
    static let coRegulationStrategies: [PredefinedStrategy] = [
        PredefinedStrategy(description: "Breathing exercises together", category: .coRegulation),
        PredefinedStrategy(description: "Calm presence (sitting nearby quietly)", category: .coRegulation),
        PredefinedStrategy(description: "Reading a favourite book together", category: .coRegulation),
        PredefinedStrategy(description: "Gentle touch or hand-holding", category: .coRegulation),
        PredefinedStrategy(description: "Singing or humming together", category: .coRegulation),
        PredefinedStrategy(description: "Mirroring movements or emotions", category: .coRegulation)
    ]

    // MARK: - Transition Support Strategies
    static let transitionStrategies: [PredefinedStrategy] = [
        PredefinedStrategy(description: "Visual timer or countdown", category: .transition),
        PredefinedStrategy(description: "Transition warnings (5 min, 2 min, 30 sec)", category: .transition),
        PredefinedStrategy(description: "Transition object (bring favourite toy)", category: .transition),
        PredefinedStrategy(description: "First-Then board", category: .transition),
        PredefinedStrategy(description: "Transition song or routine", category: .transition),
        PredefinedStrategy(description: "Extra processing time before switching", category: .transition)
    ]

    // MARK: - Other Strategies
    static let otherStrategies: [PredefinedStrategy] = [
        PredefinedStrategy(description: "Time alone in safe space", category: .other),
        PredefinedStrategy(description: "Special interest or comfort topic", category: .other),
        PredefinedStrategy(description: "Predictable routine or ritual", category: .other),
        PredefinedStrategy(description: "Water play or bath time", category: .other),
        PredefinedStrategy(description: "Favourite calming video or show", category: .other)
    ]
}

// MARK: - Preview

struct AddStrategySheet_Previews: PreviewProvider {
    static var previews: some View {
        AddStrategySheet(
            isPresented: .constant(true),
            onAdd: { _ in }
        )
    }
}
