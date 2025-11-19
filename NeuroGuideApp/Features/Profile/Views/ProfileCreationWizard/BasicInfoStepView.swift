//
//  BasicInfoStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import SwiftUI

/// First step of profile creation: Basic information
struct BasicInfoStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Emoji/Photo section
                VStack(spacing: 16) {
                    // Emoji Picker
                    ProfileEmojiPickerView(selectedEmoji: $viewModel.profileEmoji)

                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Photo section
                    ProfilePhotoPickerView(photoData: $viewModel.photoData)
                }
                .padding(.top)

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child's Name")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    TextField("Enter name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Child's name")
                        .accessibilityHint("Enter your child's name")
                }

                // Age picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Picker("Age", selection: $viewModel.age) {
                        // Age range: 2-18 years
                        ForEach(2...18, id: \.self) { years in
                            Text("\(years) years old")
                                .tag(years)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .accessibilityLabel("Child's age")
                    .accessibilityValue("\(viewModel.age) year\(viewModel.age == 1 ? "" : "s") old")
                }

                // Pronouns field (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pronouns")
                            .font(.headline)
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    TextField("e.g., she/her, he/him, they/them", text: $viewModel.pronouns)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Pronouns")
                        .accessibilityHint("Optional. Enter preferred pronouns")
                }

                // Profile color picker
                ProfileColorPickerView(selectedColor: $viewModel.profileColor)

                // Info card
                InfoCard(
                    icon: "info.circle.fill",
                    title: "Privacy First",
                    message: "All information is stored securely on your device and never shared."
                )

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Info Card Component

struct InfoCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Profile Emoji Picker

struct ProfileEmojiPickerView: View {
    @Binding var selectedEmoji: String

    // Curated list of child/person emojis with diverse skin tones
    let availableEmojis = [
        // Girls with different skin tones
        "👧🏻", "👧🏼", "👧🏽", "👧🏾", "👧🏿",
        // Boys with different skin tones
        "👦🏻", "👦🏼", "👦🏽", "👦🏾", "👦🏿",
        // Gender neutral children
        "🧒🏻", "🧒🏼", "🧒🏽", "🧒🏾", "🧒🏿",
        // Babies
        "👶🏻", "👶🏼", "👶🏽", "👶🏾", "👶🏿",
        // Fun characters
        "😊", "😁", "🥰", "😎", "🤓", "😇", "🤗",
        "🦖", "🦕", "🐶", "🐱", "🐻", "🐼", "🦊",
        "🦁", "🐯", "🐨", "🐸", "🐙", "🦄", "🌟"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Profile Emoji")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Selected emoji preview
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                Text(selectedEmoji)
                    .font(.system(size: 60))
            }
            .frame(maxWidth: .infinity)

            // Emoji grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 50), spacing: 12)
                ], spacing: 12) {
                    ForEach(availableEmojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            AccessibilityHelper.shared.selection()
                        }) {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Emoji: \(emoji)")
                        .accessibilityAddTraits(selectedEmoji == emoji ? [.isSelected] : [])
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }
}

// MARK: - Preview

struct BasicInfoStepView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoStepView(viewModel: ProfileCreationViewModel())
    }
}
