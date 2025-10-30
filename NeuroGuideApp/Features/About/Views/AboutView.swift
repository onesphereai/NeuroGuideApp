//
//  AboutView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI

/// About NeuroGuide screen with app info, mission, and team
struct AboutView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon & Name
                appHeaderView

                // Mission Statement
                missionView

                // Key Features
                featuresView

                // Team & Credits
                teamView

                // Links
                linksView

                // Version Info
                versionView

                Spacer(minLength: 32)
            }
            .padding()
        }
        .navigationTitle("About attune")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AccessibilityHelper.announce("About attune")
        }
    }

    // MARK: - App Header

    private var appHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("attune")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Supporting families through neurodiversity")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("attune: Supporting families through neurodiversity")
    }

    // MARK: - Mission View

    private var missionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Our Mission")
                .font(.headline)
                .foregroundColor(.primary)

            Text("""
            NeuroGuide helps parents and caregivers better understand and support their autistic children through guided check-in sessions, pattern tracking, and evidence-based strategies.

            We believe in neurodiversity-affirming care that celebrates differences while providing practical support for daily challenges.
            """)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Features View

    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Features")
                .font(.headline)
                .foregroundColor(.primary)

            FeatureRow(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Guided Check-Ins",
                description: "Structured conversations to understand your child's needs",
                color: .blue
            )

            FeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Pattern Recognition",
                description: "Identify triggers, preferences, and effective strategies",
                color: .green
            )

            FeatureRow(
                icon: "lock.fill",
                title: "Privacy First",
                description: "All data stays on your device by default",
                color: .purple
            )

            FeatureRow(
                icon: "accessibility",
                title: "Accessible Design",
                description: "Built with VoiceOver and accessibility in mind",
                color: .orange
            )
        }
    }

    // MARK: - Team View

    private var teamView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Built With Care")
                .font(.headline)
                .foregroundColor(.primary)

            Text("""
            NeuroGuide is developed in collaboration with autistic adults, parents, and healthcare professionals to ensure our approach is both practical and neurodiversity-affirming.

            Special thanks to our advisory board and the families who've shared their experiences to make this app better.
            """)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Links View

    private var linksView: some View {
        VStack(spacing: 12) {
            LinkButton(
                icon: "globe",
                title: "Visit Our Website",
                url: "https://neuroguide.app",
                color: .blue
            )

            LinkButton(
                icon: "message.fill",
                title: "Community Forum",
                url: "https://community.neuroguide.app",
                color: .purple
            )

            LinkButton(
                icon: "book.fill",
                title: "Resources & Research",
                url: "https://neuroguide.app/resources",
                color: .green
            )
        }
    }

    // MARK: - Version View

    private var versionView: some View {
        VStack(spacing: 8) {
            Text("Version \(appVersion())")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Build \(buildNumber())")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("© 2025 attune. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("App version \(appVersion()), build \(buildNumber()). Copyright 2025 attune. All rights reserved.")
    }

    // MARK: - Private Methods

    private func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.0"
    }

    private func buildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .cornerRadius(10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Link Button

struct LinkButton: View {
    let icon: String
    let title: String
    let url: String
    let color: Color

    var body: some View {
        Button(action: {
            AccessibilityHelper.shared.buttonTap()
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .cornerRadius(8)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open in browser")
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AboutView()
    }
}
