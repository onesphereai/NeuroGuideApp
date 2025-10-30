//
//  AddStrategySheet.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Modal sheet for adding a new strategy
struct AddStrategySheet: View {
    @Binding var isPresented: Bool
    let onAdd: (Strategy) -> Void

    @State private var description: String = ""
    @State private var category: StrategyCategory = .sensory

    @FocusState private var isDescriptionFocused: Bool

    var canAdd: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                // Description section
                Section {
                    TextField("e.g., Deep pressure hugs", text: $description)
                        .focused($isDescriptionFocused)
                        .accessibilityLabel("Strategy description")
                        .accessibilityHint("Enter a description of a soothing strategy")
                } header: {
                    Text("Description")
                } footer: {
                    Text("Describe a strategy that helps your child regulate when overwhelmed")
                        .font(.caption)
                }

                // Category section
                Section {
                    ForEach(StrategyCategory.allCases, id: \.self) { cat in
                        Button(action: { category = cat }) {
                            HStack {
                                Image(systemName: cat.icon)
                                    .font(.body)
                                    .foregroundColor(.green)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cat.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(cat.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if category == cat {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Category")
                }

                // Examples section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples:")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text("• Deep pressure (hugs, weighted blanket)")
                        Text("• Movement (jumping, swinging)")
                        Text("• Breathing exercises")
                        Text("• Quiet space with dim lights")
                        Text("• Fidget toys or sensory items")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Strategy")
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
                            description: description.trimmingCharacters(in: .whitespaces),
                            category: category,
                            effectivenessRating: 0.0
                        )
                        onAdd(strategy)
                        isPresented = false
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Auto-focus description field
                isDescriptionFocused = true
            }
        }
    }
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
