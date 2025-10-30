//
//  NGTextField.swift
//  NeuroGuide
//
//  Unit 12 - Design System Components (US-038)
//  Branded text input components for Attune
//

import SwiftUI

// MARK: - Text Field

/// Branded text field with label and validation
struct NGTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    let errorMessage: String?
    let helperText: String?

    @FocusState private var isFocused: Bool

    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        helperText: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.helperText = helperText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.xs) {
            // Label
            Text(label)
                .font(.ngCalloutSemibold)
                .foregroundColor(.ngTextPrimary)

            // Input field
            HStack(spacing: NGSpacing.sm) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }

                // Text input
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.ngBody)
                        .foregroundColor(.ngTextPrimary)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.ngBody)
                        .foregroundColor(.ngTextPrimary)
                        .focused($isFocused)
                }
            }
            .padding(NGSpacing.md)
            .background(Color.ngSurface)
            .cornerRadius(NGRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: NGRadius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )

            // Helper or error text
            if let errorMessage = errorMessage {
                HStack(spacing: NGSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.ngError)

                    Text(errorMessage)
                        .font(.ngCaption)
                        .foregroundColor(.ngError)
                }
            } else if let helperText = helperText {
                Text(helperText)
                    .font(.ngCaption)
                    .foregroundColor(.ngTextSecondary)
            }
        }
    }

    // MARK: - Style Properties

    private var borderColor: Color {
        if errorMessage != nil {
            return .ngError
        } else if isFocused {
            return .ngPrimaryBlue
        } else {
            return .ngBorder
        }
    }

    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }

    private var iconColor: Color {
        if errorMessage != nil {
            return .ngError
        } else if isFocused {
            return .ngPrimaryBlue
        } else {
            return .ngTextTertiary
        }
    }
}

// MARK: - Text Editor (Multi-line)

/// Branded multi-line text editor
struct NGTextEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    let errorMessage: String?
    let helperText: String?

    @FocusState private var isFocused: Bool

    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        minHeight: CGFloat = 120,
        errorMessage: String? = nil,
        helperText: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
        self.errorMessage = errorMessage
        self.helperText = helperText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.xs) {
            // Label
            Text(label)
                .font(.ngCalloutSemibold)
                .foregroundColor(.ngTextPrimary)

            // Text editor
            ZStack(alignment: .topLeading) {
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(.ngBody)
                        .foregroundColor(.ngTextTertiary)
                        .padding(NGSpacing.md)
                }

                // Editor
                TextEditor(text: $text)
                    .font(.ngBody)
                    .foregroundColor(.ngTextPrimary)
                    .focused($isFocused)
                    .padding(NGSpacing.sm)
                    .scrollContentBackground(.hidden)
            }
            .frame(minHeight: minHeight)
            .background(Color.ngSurface)
            .cornerRadius(NGRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: NGRadius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )

            // Helper or error text
            if let errorMessage = errorMessage {
                HStack(spacing: NGSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.ngError)

                    Text(errorMessage)
                        .font(.ngCaption)
                        .foregroundColor(.ngError)
                }
            } else if let helperText = helperText {
                Text(helperText)
                    .font(.ngCaption)
                    .foregroundColor(.ngTextSecondary)
            }
        }
    }

    // MARK: - Style Properties

    private var borderColor: Color {
        if errorMessage != nil {
            return .ngError
        } else if isFocused {
            return .ngPrimaryBlue
        } else {
            return .ngBorder
        }
    }

    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }
}

// MARK: - Search Field

/// Branded search field with clear button
struct NGSearchField: View {
    let placeholder: String
    @Binding var text: String
    let onSubmit: (() -> Void)?

    init(
        placeholder: String = "Search",
        text: Binding<String>,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: NGSpacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.ngTextTertiary)

            // Text input
            TextField(placeholder, text: $text)
                .font(.ngBody)
                .foregroundColor(.ngTextPrimary)
                .onSubmit {
                    onSubmit?()
                }

            // Clear button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.ngTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(NGSpacing.md)
        .background(Color.ngSurface)
        .cornerRadius(NGRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: NGRadius.md)
                .stroke(Color.ngBorder, lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("Text Input Components") {
    ScrollView {
        VStack(spacing: NGSpacing.lg) {
            Text("Text Input Components")
                .font(.ngTitle2)
                .padding(.top)

            NGTextField(
                label: "Email Address",
                placeholder: "you@example.com",
                text: .constant(""),
                icon: "envelope",
                helperText: "We'll never share your email"
            )

            NGTextField(
                label: "Password",
                placeholder: "Enter password",
                text: .constant(""),
                icon: "lock",
                isSecure: true
            )

            NGTextField(
                label: "Username",
                placeholder: "Choose a username",
                text: .constant("invalid@"),
                icon: "person",
                errorMessage: "Username contains invalid characters"
            )

            NGSearchField(
                placeholder: "Search resources...",
                text: .constant("autism support")
            )

            NGTextEditor(
                label: "Additional Notes",
                placeholder: "Enter any additional information...",
                text: .constant(""),
                helperText: "Optional: Add context to help us understand better"
            )
        }
        .padding()
    }
}
