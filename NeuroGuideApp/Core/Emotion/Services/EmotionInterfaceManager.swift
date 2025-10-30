//
//  EmotionInterfaceManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation
import Combine

/// Manager for emotion interface consent and state
@MainActor
class EmotionInterfaceManager: EmotionInterfaceService, ObservableObject {
    // MARK: - Singleton

    static let shared = EmotionInterfaceManager()

    // MARK: - Published Properties

    @Published private(set) var consentStatus: EmotionConsentStatus

    // MARK: - Computed Properties

    var isEnabled: Bool {
        return consentStatus.isActive
    }

    var consentPublisher: AnyPublisher<EmotionConsentStatus, Never> {
        return $consentStatus.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let storage: EmotionStorageService
    private let storageKey = "EmotionConsentStatus"

    // MARK: - Initialization

    init(storage: EmotionStorageService = UserDefaults.standard) {
        self.storage = storage

        // Load saved consent status
        if let data = storage.data(forKey: storageKey),
           let savedStatus = try? JSONDecoder().decode(EmotionConsentStatus.self, from: data) {
            self.consentStatus = savedStatus
        } else {
            self.consentStatus = EmotionConsentStatus()
        }

        print("📊 Emotion Interface initialized - Enabled: \(isEnabled)")
    }

    // MARK: - Consent Management

    func enable() async throws {
        consentStatus.grantConsent()
        try await save()

        print("✅ Emotion interface enabled")
    }

    func disable() async throws {
        consentStatus.revokeConsent()
        try await save()

        print("⏸️ Emotion interface disabled")
    }

    func markModelCardViewed() async {
        consentStatus.markModelCardViewed()
        try? await save()
    }

    func showDemoVideo() async {
        // TODO: Implement demo video playback
        consentStatus.markDemoWatched()
        try? await save()

        print("📹 Demo video shown")
    }

    func getModelCard() -> EmotionModelCard {
        return EmotionModelCard.current
    }

    // MARK: - Parent Monitoring

    func enableParentMonitoring() async throws {
        guard isEnabled else {
            throw EmotionInterfaceError.consentNotGranted
        }

        consentStatus.enableParentMonitoring()
        try await save()

        print("✅ Parent emotion monitoring enabled")
    }

    func disableParentMonitoring() async throws {
        consentStatus.disableParentMonitoring()
        try await save()

        print("⏸️ Parent emotion monitoring disabled")
    }

    // MARK: - Storage

    private func save() async throws {
        let data = try JSONEncoder().encode(consentStatus)
        storage.set(data, forKey: storageKey)
    }
}

/// Protocol for storage abstraction (allows testing)
protocol EmotionStorageService {
    func data(forKey key: String) -> Data?
    func set(_ value: Any?, forKey key: String)
}

/// UserDefaults conformance
extension UserDefaults: EmotionStorageService {
    // UserDefaults already implements both required methods
}
