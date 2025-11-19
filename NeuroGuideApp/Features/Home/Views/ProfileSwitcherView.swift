//
//  ProfileSwitcherView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-03.
//  Instagram-style profile switcher for multi-profile navigation
//

import SwiftUI

/// Instagram-style horizontal profile switcher
/// Displays all child profiles at the top of the home screen
struct ProfileSwitcherView: View {

    // MARK: - Properties

    let profiles: [ChildProfile]
    let currentProfile: ChildProfile?
    let onProfileSelect: (ChildProfile) -> Void
    let onAddProfile: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Current and other profiles
                ForEach(profiles) { profile in
                    ProfileAvatarButton(
                        profile: profile,
                        isActive: profile.id == currentProfile?.id,
                        action: {
                            AccessibilityHelper.shared.buttonTap()
                            onProfileSelect(profile)
                        }
                    )
                }

                // Add new profile button
                AddProfileButton(action: {
                    AccessibilityHelper.shared.buttonTap()
                    onAddProfile()
                })
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Profile Avatar Button

struct ProfileAvatarButton: View {
    let profile: ChildProfile
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Gradient ring for active profile (like Instagram stories)
                    if isActive {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 74, height: 74)
                    }

                    // Avatar circle
                    Circle()
                        .fill(avatarColor(for: profile))
                        .frame(width: 68, height: 68)
                        .overlay(
                            Text(initials(for: profile))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }

                // Name label
                Text(profile.name)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)
                    .frame(width: 74)
            }
        }
        .accessibilityLabel("\(profile.name)'s profile")
        .accessibilityHint(isActive ? "Currently selected" : "Double tap to switch to this profile")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    // MARK: - Helper Methods

    private func initials(for profile: ChildProfile) -> String {
        let components = profile.name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else {
            return String(profile.name.prefix(2)).uppercased()
        }
    }

    private func avatarColor(for profile: ChildProfile) -> Color {
        // Generate consistent color based on profile ID
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .indigo, .teal]
        let hash = abs(profile.id.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Add Profile Button

struct AddProfileButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                    )

                Text("Add")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityLabel("Add new profile")
        .accessibilityHint("Double tap to create a new child profile")
    }
}

// MARK: - Preview

#Preview("Profile Switcher") {
    VStack {
        ProfileSwitcherView(
            profiles: [
                ChildProfile(
                    name: "Emma Johnson",
                    age: 8
                ),
                ChildProfile(
                    name: "Liam",
                    age: 6
                ),
                ChildProfile(
                    name: "Sophia",
                    age: 10
                )
            ],
            currentProfile: ChildProfile(
                name: "Emma Johnson",
                age: 8
            ),
            onProfileSelect: { _ in },
            onAddProfile: { }
        )
        Spacer()
    }
}
