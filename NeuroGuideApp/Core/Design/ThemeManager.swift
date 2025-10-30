//
//  ThemeManager.swift
//  NeuroGuide
//
//  Unit 12 - Theme Support/Manager (US-039)
//  Manages app-wide theme preferences (light/dark mode)
//

import SwiftUI
import Combine

/// Theme appearance options
enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil // Use system preference
        }
    }
}

/// Manages theme preferences and appearance settings
class ThemeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Published Properties

    /// Current theme mode
    @Published var themeMode: ThemeMode {
        didSet {
            saveThemePreference()
            print("🎨 Theme changed to: \(themeMode.rawValue)")
        }
    }

    /// Whether reduced motion is enabled
    @Published var reduceMotion: Bool {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "reduce_motion")
        }
    }

    /// Whether high contrast is enabled
    @Published var highContrast: Bool {
        didSet {
            UserDefaults.standard.set(highContrast, forKey: "high_contrast")
            print("🎨 High contrast: \(highContrast ? "enabled" : "disabled")")
        }
    }

    // MARK: - Initialization

    private init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "theme_mode"),
           let mode = ThemeMode(rawValue: savedTheme) {
            self.themeMode = mode
        } else {
            self.themeMode = .system // Default to system
        }

        // Load accessibility preferences
        self.reduceMotion = UserDefaults.standard.bool(forKey: "reduce_motion")
        self.highContrast = UserDefaults.standard.bool(forKey: "high_contrast")

        print("✅ ThemeManager initialized with mode: \(themeMode.rawValue)")
    }

    // MARK: - Public Methods

    /// Set theme mode
    func setTheme(_ mode: ThemeMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            themeMode = mode
        }

        // Provide haptic feedback
        AccessibilityHelper.shared.selection()
    }

    /// Toggle between light and dark mode
    func toggleTheme() {
        switch themeMode {
        case .light:
            setTheme(.dark)
        case .dark:
            setTheme(.light)
        case .system:
            // If system, toggle to light
            setTheme(.light)
        }
    }

    /// Get current effective color scheme
    func effectiveColorScheme(for environment: ColorScheme?) -> ColorScheme {
        if let scheme = themeMode.colorScheme {
            return scheme
        }
        // Fall back to environment (system preference)
        return environment ?? .light
    }

    // MARK: - Private Methods

    private func saveThemePreference() {
        UserDefaults.standard.set(themeMode.rawValue, forKey: "theme_mode")
    }
}

// MARK: - View Extension

extension View {
    /// Apply theme-aware preferred color scheme
    func applyTheme(_ themeManager: ThemeManager = .shared) -> some View {
        self.preferredColorScheme(themeManager.themeMode.colorScheme)
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Theme Picker View

/// Theme selection picker component
struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager

    init(themeManager: ThemeManager = .shared) {
        self.themeManager = themeManager
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.md) {
            Text("Appearance")
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            HStack(spacing: NGSpacing.md) {
                ForEach(ThemeMode.allCases) { mode in
                    ThemeOptionButton(
                        mode: mode,
                        isSelected: themeManager.themeMode == mode
                    ) {
                        themeManager.setTheme(mode)
                    }
                }
            }

            Text("Choose how attune looks. System follows your device settings.")
                .font(.ngCaption)
                .foregroundColor(.ngTextSecondary)
                .padding(.top, NGSpacing.xxs)
        }
    }
}

// MARK: - Theme Option Button

private struct ThemeOptionButton: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NGSpacing.sm) {
                Image(systemName: mode.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .ngTextPrimary)

                Text(mode.rawValue)
                    .font(.ngCallout)
                    .foregroundColor(isSelected ? .white : .ngTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NGSpacing.md)
            .background(
                isSelected ?
                LinearGradient(
                    gradient: Gradient(colors: [Color.ngPrimaryBlue, Color.ngSecondaryPurple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Color.ngSurface, Color.ngSurface]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(NGRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: NGRadius.lg)
                    .stroke(isSelected ? Color.clear : Color.ngBorder, lineWidth: 1)
            )
            .shadow(
                color: isSelected ? Color.ngPrimaryBlue.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.rawValue) mode")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Accessibility Settings Card

/// Card for accessibility-related theme settings
struct AccessibilityThemeCard: View {
    @ObservedObject var themeManager: ThemeManager

    init(themeManager: ThemeManager = .shared) {
        self.themeManager = themeManager
    }

    var body: some View {
        NGCard {
            VStack(alignment: .leading, spacing: NGSpacing.md) {
                Text("Visual Accessibility")
                    .font(.ngBodySemibold)
                    .foregroundColor(.ngTextPrimary)

                // High Contrast Toggle
                Toggle(isOn: $themeManager.highContrast) {
                    VStack(alignment: .leading, spacing: NGSpacing.xxs) {
                        Text("High Contrast")
                            .font(.ngBody)
                            .foregroundColor(.ngTextPrimary)

                        Text("Increases contrast for better visibility")
                            .font(.ngCaption)
                            .foregroundColor(.ngTextSecondary)
                    }
                }
                .tint(.ngPrimaryBlue)

                Divider()
                    .background(Color.ngDivider)

                // Reduce Motion Toggle
                Toggle(isOn: $themeManager.reduceMotion) {
                    VStack(alignment: .leading, spacing: NGSpacing.xxs) {
                        Text("Reduce Motion")
                            .font(.ngBody)
                            .foregroundColor(.ngTextPrimary)

                        Text("Minimizes animations and transitions")
                            .font(.ngCaption)
                            .foregroundColor(.ngTextSecondary)
                    }
                }
                .tint(.ngPrimaryBlue)
            }
        }
    }
}

// MARK: - Previews

#Preview("Theme Picker") {
    VStack(spacing: NGSpacing.lg) {
        ThemePickerView()
        AccessibilityThemeCard()
    }
    .padding()
}
