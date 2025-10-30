//
//  AddTriggerSheet.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Modal sheet for adding a new trigger
struct AddTriggerSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (Trigger) -> Void

    @State private var description: String = ""
    @State private var category: TriggerCategory = .sensory

    @FocusState private var isDescriptionFocused: Bool

    var canAdd: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                // Description section
                Section {
                    TextField("e.g., Loud sudden noises", text: $description)
                        .focused($isDescriptionFocused)
                        .accessibilityLabel("Trigger description")
                        .accessibilityHint("Enter a description of what triggers dysregulation")
                } header: {
                    Text("Description")
                } footer: {
                    Text("Describe what triggers dysregulation for your child")
                        .font(.caption)
                }

                // Category section
                Section {
                    ForEach(TriggerCategory.allCases, id: \.self) { cat in
                        Button(action: { category = cat }) {
                            HStack {
                                Image(systemName: cat.icon)
                                    .font(.body)
                                    .foregroundColor(.orange)
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
            }
            .navigationTitle("Add Trigger")
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
                            description: description.trimmingCharacters(in: .whitespaces),
                            category: category
                        )
                        onAdd(trigger)
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

struct AddTriggerSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddTriggerSheet(
            isPresented: .constant(true),
            onAdd: { _ in }
        )
    }
}
