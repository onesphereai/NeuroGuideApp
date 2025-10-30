//
//  ProfileSummaryView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.1 - App Shell & Navigation
//

import SwiftUI

/// Profile summary component for home screen
/// Displays child profile information
struct ProfileSummaryView: View {

    // MARK: - Properties

    let profile: ChildProfile?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            // Profile avatar
            if let photoData = profile?.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    )
                    .accessibilityHidden(true)
            }

            // Profile info
            VStack(alignment: .leading, spacing: 4) {
                if let profile = profile {
                    Text(profile.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text("\(profile.age) years old")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let pronouns = profile.pronouns, !pronouns.isEmpty {
                            Text("• \(pronouns)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Welcome Back!")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Set up your child's profile to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier("profile_summary_view")
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if let profile = profile {
            var label = profile.displayName
            label += ", \(profile.age) years old"
            if let pronouns = profile.pronouns, !pronouns.isEmpty {
                label += ", \(pronouns)"
            }
            return label
        } else {
            return "Welcome back! Set up your child's profile to get started"
        }
    }

    private var accessibilityHint: String {
        if profile != nil {
            return "Double tap to view or edit profile"
        } else {
            return "Double tap to set up profile"
        }
    }
}

// MARK: - Preview Provider

struct ProfileSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // No profile
            ProfileSummaryView(profile: nil)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("No Profile")

            // With profile
            ProfileSummaryView(profile: ChildProfile(
                name: "Sam",
                age: 5,
                pronouns: "they/them",
                photoData: nil
            ))
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("With Profile")

            // Dark mode
            ProfileSummaryView(profile: ChildProfile(
                name: "Sam",
                age: 5,
                pronouns: "they/them",
                photoData: nil
            ))
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Dark Mode")
        }
    }
}
