//
//  LegalView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI

/// Legal information screen with privacy policy and terms
struct LegalView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        List {
            Section {
                NavigationLink(destination: PrivacyPolicyView()) {
                    LegalRowView(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        iconColor: .green
                    )
                }

                NavigationLink(destination: TermsOfServiceView()) {
                    LegalRowView(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        iconColor: .blue
                    )
                }

                NavigationLink(destination: OpenSourceLicensesView()) {
                    LegalRowView(
                        icon: "doc.plaintext.fill",
                        title: "Open Source Licenses",
                        iconColor: .purple
                    )
                }
            } header: {
                Text("Legal Documents")
            }

            Section {
                HStack {
                    Text("Last Updated")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("January 2025")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Terms & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AccessibilityHelper.announce("Terms and Privacy")
        }
    }
}

// MARK: - Legal Row View

struct LegalRowView: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .cornerRadius(8)
                .accessibilityHidden(true)

            Text(title)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Effective Date: January 1, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    SectionHeader(title: "1. Information We Collect")
                    BodyText("""
                    NeuroGuide is designed with privacy as a core principle. By default, all your data stays on your device.

                    **Data Stored Locally:**
                    • Child profiles (names, age, preferences)
                    • Session check-in responses and summaries
                    • Your notes and observations
                    • App settings and preferences

                    **Data We Don't Collect:**
                    • No medical or health information
                    • No location data
                    • No browsing history
                    • No device identifiers
                    • No analytics or tracking data
                    """)

                    SectionHeader(title: "2. How We Use Your Information")
                    BodyText("""
                    Your data is used solely to:
                    • Provide app functionality (sessions, profiles, history)
                    • Display patterns and insights within the app
                    • Remember your settings and preferences

                    Your data is NEVER:
                    • Sold to third parties
                    • Used for advertising
                    • Shared without your explicit consent
                    • Analyzed by external services
                    """)

                    SectionHeader(title: "3. Optional Cloud Sync")
                    BodyText("""
                    If you enable cloud sync (optional):
                    • Data is encrypted end-to-end
                    • Stored securely on Apple iCloud
                    • Only accessible by you
                    • Can be disabled anytime
                    • Deleted when you delete the app

                    We never have access to your cloud-synced data.
                    """)

                    SectionHeader(title: "4. Data Retention")
                    BodyText("""
                    You control how long data is kept:
                    • Set retention periods in Settings
                    • Enable auto-delete for old sessions
                    • Manually delete individual sessions
                    • Delete entire profiles anytime
                    • All deletions are permanent
                    """)

                    SectionHeader(title: "5. Children's Privacy")
                    BodyText("""
                    NeuroGuide is designed for parents/caregivers, not children directly. We:
                    • Don't collect data directly from children
                    • Require parent/caregiver account
                    • Store minimal child information
                    • Comply with COPPA requirements
                    """)

                    SectionHeader(title: "6. Security")
                    BodyText("""
                    We protect your data through:
                    • iOS secure storage (Keychain)
                    • On-device encryption
                    • No external data transmission (by default)
                    • Regular security reviews
                    • Secure coding practices
                    """)

                    SectionHeader(title: "7. Your Rights")
                    BodyText("""
                    You have the right to:
                    • Access all your data
                    • Export your data
                    • Delete your data anytime
                    • Disable cloud sync
                    • Use the app completely offline
                    """)

                    SectionHeader(title: "8. Contact Us")
                    BodyText("""
                    Questions about privacy?
                    Email: privacy@neuroguide.app
                    Website: neuroguide.app/privacy

                    We respond within 48 hours.
                    """)
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Effective Date: January 1, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    SectionHeader(title: "1. Acceptance of Terms")
                    BodyText("""
                    By using NeuroGuide, you agree to these Terms of Service. If you don't agree, please don't use the app.
                    """)

                    SectionHeader(title: "2. Description of Service")
                    BodyText("""
                    NeuroGuide provides:
                    • Guided check-in sessions for parents/caregivers
                    • Tools to track patterns and strategies
                    • Educational content about neurodiversity
                    • On-device data storage

                    NeuroGuide is NOT:
                    • Medical or therapeutic advice
                    • A substitute for professional care
                    • Crisis intervention service
                    • Diagnostic tool
                    """)

                    SectionHeader(title: "3. Medical Disclaimer")
                    BodyText("""
                    **IMPORTANT:**
                    NeuroGuide is for informational purposes only. It does not provide medical advice, diagnosis, or treatment.

                    Always seek the advice of qualified healthcare professionals with questions about your child's health or development.

                    In case of emergency, call 911 or your local emergency services.
                    """)

                    SectionHeader(title: "4. User Responsibilities")
                    BodyText("""
                    You agree to:
                    • Provide accurate information
                    • Use the app legally and appropriately
                    • Maintain security of your device
                    • Not share your account access
                    • Supervise any child's interaction with the app
                    """)

                    SectionHeader(title: "5. Content and Accuracy")
                    BodyText("""
                    While we strive for accuracy:
                    • Content is for general information
                    • May not reflect latest research
                    • Should not replace professional advice
                    • Is provided "as is" without warranties
                    """)

                    SectionHeader(title: "6. Limitation of Liability")
                    BodyText("""
                    To the fullest extent permitted by law, NeuroGuide and its creators are not liable for:
                    • Decisions made based on app content
                    • Data loss (keep backups!)
                    • Service interruptions
                    • Third-party links or content
                    """)

                    SectionHeader(title: "7. Changes to Terms")
                    BodyText("""
                    We may update these terms occasionally. Continued use after changes means you accept the new terms.

                    Major changes will be announced in-app.
                    """)

                    SectionHeader(title: "8. Termination")
                    BodyText("""
                    You may stop using NeuroGuide anytime by deleting the app.

                    We may terminate service for:
                    • Violation of these terms
                    • Abusive behavior
                    • Legal requirements
                    """)

                    SectionHeader(title: "9. Contact")
                    BodyText("""
                    Questions about these terms?
                    Email: legal@neuroguide.app
                    Website: neuroguide.app/terms
                    """)
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Open Source Licenses View

struct OpenSourceLicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Open Source Licenses")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                NeuroGuide is built with the help of open source software. We're grateful to the open source community.
                """)
                    .font(.body)
                    .foregroundColor(.secondary)

                Group {
                    LicenseBlock(
                        name: "SwiftUI",
                        author: "Apple Inc.",
                        license: "Apple Software License",
                        url: "https://developer.apple.com"
                    )

                    Text("""
                    Additional third-party libraries and their licenses will be listed here as they are integrated.
                    """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
        }
        .navigationTitle("Open Source")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Components

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.top, 8)
    }
}

struct BodyText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct LicenseBlock: View {
    let name: String
    let author: String
    let license: String
    let url: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
                .foregroundColor(.primary)

            Text("By \(author)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(license)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(url)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LegalView()
    }
}
