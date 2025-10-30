//
//  SupportView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI
import MessageUI

/// Contact support screen with form and email integration
struct SupportView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - State

    @State private var name = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory: SupportCategory = .general
    @State private var showingMailComposer = false
    @State private var showingMailError = false
    @State private var showingSuccessMessage = false

    // MARK: - Support Categories

    enum SupportCategory: String, CaseIterable {
        case general = "General Question"
        case technical = "Technical Issue"
        case feedback = "Feedback"
        case accessibility = "Accessibility"
        case privacy = "Privacy Concern"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView

                // Form
                formView

                // Submit Button
                submitButton

                // Alternative Contact Methods
                alternativeContactsView

                Spacer(minLength: 32)
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(
                recipient: "support@neuroguide.app",
                subject: "[\(selectedCategory.rawValue)] \(subject)",
                body: composeEmailBody()
            )
        }
        .alert("Email Not Available", isPresented: $showingMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your device is not configured to send email. Please email us directly at support@neuroguide.app")
        }
        .alert("Message Sent!", isPresented: $showingSuccessMessage) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Thank you for contacting us. We'll get back to you as soon as possible.")
        }
        .onAppear {
            AccessibilityHelper.announce("Contact support")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("How can we help?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("We typically respond within 24-48 hours")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Contact support. We typically respond within 24 to 48 hours")
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: 16) {
            // Category Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Picker("Category", selection: $selectedCategory) {
                    ForEach(SupportCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .accessibilityLabel("Support category")
                .accessibilityValue(selectedCategory.rawValue)
            }

            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                TextField("Your name", text: $name)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .accessibilityLabel("Your name, optional")
                    .accessibilityIdentifier("support_name_field")
            }

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                TextField("your@email.com", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .accessibilityLabel("Email address")
                    .accessibilityIdentifier("support_email_field")
            }

            // Subject Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Subject")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                TextField("Brief description", text: $subject)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .accessibilityLabel("Subject")
                    .accessibilityIdentifier("support_subject_field")
            }

            // Message Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                TextEditor(text: $message)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .accessibilityLabel("Message details")
                    .accessibilityIdentifier("support_message_field")
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: submitForm) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                Text("Send Message")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid)
        .accessibilityLabel("Send message")
        .accessibilityHint(isFormValid ? "Double tap to send your support message" : "Fill in required fields to enable")
        .accessibilityIdentifier("support_submit_button")
    }

    // MARK: - Alternative Contacts

    private var alternativeContactsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other Ways to Reach Us")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ContactMethodRow(
                    icon: "envelope.fill",
                    title: "Email",
                    detail: "support@neuroguide.app",
                    iconColor: .blue,
                    action: {
                        if let url = URL(string: "mailto:support@neuroguide.app") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                ContactMethodRow(
                    icon: "globe",
                    title: "Website",
                    detail: "neuroguide.app/support",
                    iconColor: .green,
                    action: {
                        if let url = URL(string: "https://neuroguide.app/support") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                ContactMethodRow(
                    icon: "message.fill",
                    title: "Community Forum",
                    detail: "Share ideas with other parents",
                    iconColor: .purple,
                    action: {
                        if let url = URL(string: "https://community.neuroguide.app") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !email.isEmpty &&
        !subject.isEmpty &&
        !message.isEmpty &&
        isValidEmail(email)
    }

    // MARK: - Private Methods

    private func submitForm() {
        AccessibilityHelper.shared.buttonTap()

        // Check if mail composer is available
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            // Fallback: show email address
            showingMailError = true
        }
    }

    private func composeEmailBody() -> String {
        var body = ""

        if !name.isEmpty {
            body += "Name: \(name)\n"
        }

        body += "Email: \(email)\n\n"
        body += "Message:\n\(message)\n\n"
        body += "---\n"
        body += "App Version: \(appVersion())\n"
        body += "iOS Version: \(iosVersion())\n"
        body += "Device: \(deviceModel())\n"

        return body
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func appVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private func iosVersion() -> String {
        return UIDevice.current.systemVersion
    }

    private func deviceModel() -> String {
        return UIDevice.current.model
    }
}

// MARK: - Contact Method Row

struct ContactMethodRow: View {
    let icon: String
    let title: String
    let detail: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            AccessibilityHelper.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(iconColor)
                    .cornerRadius(8)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(detail)")
        .accessibilityHint("Double tap to open")
    }
}

// MARK: - Mail Compose View (UIKit Bridge)

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SupportView()
    }
}
