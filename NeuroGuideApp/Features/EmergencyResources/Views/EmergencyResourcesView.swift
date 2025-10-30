//
//  EmergencyResourcesView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI

/// Emergency resources and crisis hotlines view
struct EmergencyResourcesView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @StateObject private var resourcesManager = EmergencyResourcesManager()

    // MARK: - State

    @State private var showingDisclaimer = true

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Disclaimer banner
                        if showingDisclaimer {
                            DisclaimerBanner(onDismiss: {
                                withAnimation {
                                    showingDisclaimer = false
                                }
                            })
                        }

                        // Crisis resources
                        ResourceCategorySection(
                            title: "Crisis Support (24/7)",
                            resources: resourcesManager.resourcesByCategory[.crisis] ?? [],
                            iconColor: .red
                        )

                        // Autism-specific resources
                        ResourceCategorySection(
                            title: "Autism Support",
                            resources: resourcesManager.resourcesByCategory[.autism] ?? [],
                            iconColor: .blue
                        )

                        // Mental health resources
                        ResourceCategorySection(
                            title: "Mental Health",
                            resources: resourcesManager.resourcesByCategory[.mental] ?? [],
                            iconColor: .purple
                        )

                        // Local contacts
                        if let localContacts = resourcesManager.resourcesByCategory[.local],
                           !localContacts.isEmpty {
                            ResourceCategorySection(
                                title: "Your Local Contacts",
                                resources: localContacts,
                                iconColor: .green
                            )
                        }

                        // Add local contact button
                        Button(action: {
                            // TODO: Show add local contact sheet
                        }) {
                            Label("Add Local Contact", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    .padding()
                }

                // Emergency call button (floating)
                VStack {
                    Spacer()
                    EmergencyCallButton()
                        .padding()
                }
            }
            .navigationTitle("Emergency Resources")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        AccessibilityHelper.shared.buttonTap()
                        dismiss()
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Double tap to close emergency resources")
                }
            }
        }
        .onAppear {
            AccessibilityHelper.announce("Emergency Resources. This app is not for crisis intervention. Please call emergency services if needed.")
        }
    }
}

// MARK: - Disclaimer Banner

struct DisclaimerBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Important")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("Dismiss disclaimer")
            }

            Text("attune is not a crisis intervention service. If you or your child are in immediate danger, please call 911 or your local emergency services.")
                .font(.body)
                .foregroundColor(.secondary)

            Text("The resources below provide specialized support for mental health and autism-related crises.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Important disclaimer. attune is not a crisis intervention service. If you or your child are in immediate danger, please call 911 or local emergency services.")
    }
}

// MARK: - Resource Category Section

struct ResourceCategorySection: View {
    let title: String
    let resources: [EmergencyResource]
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            ForEach(resources) { resource in
                ResourceCard(resource: resource, iconColor: iconColor)
            }
        }
    }
}

// MARK: - Resource Card

struct ResourceCard: View {
    let resource: EmergencyResource
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "phone.circle.fill")
                    .font(.title2)
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.name)
                        .font(.headline)

                    if resource.isNeurodiversityFocused {
                        Text("Neurodiversity-informed")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Call button
                Button(action: {
                    callResource(resource)
                }) {
                    Text("Call")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(iconColor)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Call \(resource.name)")
                .accessibilityHint("Double tap to call \(resource.phoneNumber)")
            }

            Text(resource.description)
                .font(.body)
                .foregroundColor(.secondary)

            HStack {
                Label(resource.phoneNumber, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label(resource.availability, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(resource.name). \(resource.description). Available \(resource.availability). Phone: \(resource.phoneNumber)")
    }

    private func callResource(_ resource: EmergencyResource) {
        AccessibilityHelper.shared.buttonTap()

        // Format phone number for tel: URL
        let cleanedNumber = resource.phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if let url = URL(string: "tel://\(cleanedNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                AccessibilityHelper.announce("Calling \(resource.name)")
            }
        }
    }
}

// MARK: - Emergency Call Button

struct EmergencyCallButton: View {
    var body: some View {
        Button(action: {
            callEmergencyServices()
        }) {
            HStack {
                Image(systemName: "phone.fill")
                    .font(.title3)
                Text("Call 911")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Call 911 for emergency")
        .accessibilityHint("Double tap to call emergency services")
        .accessibilityIdentifier("emergency_call_button")
    }

    private func callEmergencyServices() {
        AccessibilityHelper.shared.buttonTap()

        if let url = URL(string: "tel://911") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                AccessibilityHelper.announce("Calling 911")
            }
        }
    }
}

// MARK: - Previews

#Preview("Emergency Resources") {
    EmergencyResourcesView()
}

#Preview("Resource Card") {
    ResourceCard(
        resource: .nationalSuicidePreventionLifeline,
        iconColor: .red
    )
    .padding()
}
