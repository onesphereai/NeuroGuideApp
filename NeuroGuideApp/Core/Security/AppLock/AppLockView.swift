//
//  AppLockView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.2 - Data Encryption & Security
//

import SwiftUI

/// Lock screen displayed when app requires biometric authentication
struct AppLockView: View {

    // MARK: - Properties

    @ObservedObject var lockManager: AppLockManager
    @State private var isAuthenticating = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: lockManager.getBiometricType().iconName)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                // Title
                VStack(spacing: 8) {
                    Text("NeuroGuide is Locked")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Use \(lockManager.getBiometricType().displayName) to unlock")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Unlock Button
                Button(action: {
                    authenticate()
                }) {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: lockManager.getBiometricType().iconName)
                            Text("Unlock with \(lockManager.getBiometricType().displayName)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Automatically attempt authentication when view appears
            authenticate()
        }
    }

    // MARK: - Methods

    private func authenticate() {
        guard !isAuthenticating else { return }

        isAuthenticating = true

        Task {
            await lockManager.attemptUnlock()
            isAuthenticating = false
        }
    }
}

// MARK: - Preview

#Preview {
    AppLockView(lockManager: AppLockManager.shared)
}
