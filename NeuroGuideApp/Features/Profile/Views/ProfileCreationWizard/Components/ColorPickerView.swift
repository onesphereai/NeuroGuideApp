//
//  ColorPickerView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-29.
//  Unit 5 - Live Coach Record-First Flow
//

import SwiftUI

/// Custom color picker for child profile color selection
struct ProfileColorPickerView: View {
    @Binding var selectedColor: String  // Hex color
    @State private var showColorPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Profile Color")
                    .font(.headline)
                Text("(Used in session visualizations)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)

            // Color preview and picker button
            Button {
                showColorPicker = true
            } label: {
                HStack {
                    // Color preview circle
                    Circle()
                        .fill(Color(hex: selectedColor) ?? .blue)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tap to choose color")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Text(selectedColor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .accessibilityLabel("Profile color")
            .accessibilityValue(selectedColor)
            .accessibilityHint("Tap to choose a color for your child's profile")

            Text("This color will be used to personalize your child's behavior spectrum in Live Coach sessions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(selectedColor: $selectedColor)
        }
    }
}

// MARK: - Color Picker Sheet

struct ColorPickerSheet: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    @State private var pickedColor: Color

    init(selectedColor: Binding<String>) {
        self._selectedColor = selectedColor
        self._pickedColor = State(initialValue: Color(hex: selectedColor.wrappedValue) ?? .blue)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Color preview
                VStack(spacing: 12) {
                    Text("Preview")
                        .font(.headline)

                    Circle()
                        .fill(pickedColor)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )

                    Text(pickedColor.toHex())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                .padding()

                // Native color picker
                ColorPicker("Choose Color", selection: $pickedColor, supportsOpacity: false)
                    .padding(.horizontal)
                    .labelsHidden()

                // Preset colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Picks")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(presetColors, id: \.self) { colorHex in
                            Button {
                                pickedColor = Color(hex: colorHex) ?? .blue
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .blue)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColor == colorHex ? Color.primary : Color.gray.opacity(0.3),
                                                lineWidth: selectedColor == colorHex ? 3 : 1
                                            )
                                    )
                            }
                            .accessibilityLabel("Color \(colorHex)")
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedColor = pickedColor.toHex()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // Preset color palette
    private let presetColors: [String] = [
        "#4A90E2",  // Blue
        "#7B68EE",  // Purple
        "#50C878",  // Emerald
        "#FF6B6B",  // Coral
        "#FFA500",  // Orange
        "#FFD700",  // Gold
        "#FF69B4",  // Pink
        "#20B2AA",  // Teal
        "#9370DB",  // Lavender
        "#32CD32",  // Lime
        "#FF7F50",  // Coral Orange
        "#4682B4",  // Steel Blue
        "#DDA0DD",  // Plum
        "#87CEEB",  // Sky Blue
        "#98FB98",  // Pale Green
        "#FFB6C1"   // Light Pink
    ]
}

// MARK: - Preview

struct ProfileColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfileColorPickerView(selectedColor: .constant("#4A90E2"))
                .padding()

            Spacer()
        }
    }
}
