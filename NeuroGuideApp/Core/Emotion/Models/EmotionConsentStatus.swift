//
//  EmotionConsentStatus.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 6 - Emotion Interface & Personalization
//

import Foundation

/// Consent status for emotion interface features
struct EmotionConsentStatus: Codable, Equatable {
    /// Whether user has opted into emotion interface
    var isEnabled: Bool

    /// When consent was given (nil if never enabled)
    var consentDate: Date?

    /// Whether user has viewed the model card
    var hasViewedModelCard: Bool

    /// Whether user has watched the demo video
    var hasWatchedDemo: Bool

    /// Whether user has opted into parent emotion monitoring
    var parentMonitoringEnabled: Bool

    /// When parent monitoring consent was given
    var parentMonitoringConsentDate: Date?

    /// User can revoke consent at any time
    var revokedDate: Date?

    init(
        isEnabled: Bool = false,
        consentDate: Date? = nil,
        hasViewedModelCard: Bool = false,
        hasWatchedDemo: Bool = false,
        parentMonitoringEnabled: Bool = false,
        parentMonitoringConsentDate: Date? = nil,
        revokedDate: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.consentDate = consentDate
        self.hasViewedModelCard = hasViewedModelCard
        self.hasWatchedDemo = hasWatchedDemo
        self.parentMonitoringEnabled = parentMonitoringEnabled
        self.parentMonitoringConsentDate = parentMonitoringConsentDate
        self.revokedDate = revokedDate
    }

    /// Whether consent is currently active (enabled and not revoked)
    var isActive: Bool {
        return isEnabled && revokedDate == nil
    }

    /// Whether user needs to complete onboarding steps
    var needsOnboarding: Bool {
        return !hasViewedModelCard
    }

    /// Grant consent
    mutating func grantConsent() {
        isEnabled = true
        consentDate = Date()
        revokedDate = nil
    }

    /// Revoke consent
    mutating func revokeConsent() {
        isEnabled = false
        revokedDate = Date()
    }

    /// Mark model card as viewed
    mutating func markModelCardViewed() {
        hasViewedModelCard = true
    }

    /// Mark demo as watched
    mutating func markDemoWatched() {
        hasWatchedDemo = true
    }

    /// Enable parent monitoring
    mutating func enableParentMonitoring() {
        parentMonitoringEnabled = true
        parentMonitoringConsentDate = Date()
    }

    /// Disable parent monitoring
    mutating func disableParentMonitoring() {
        parentMonitoringEnabled = false
    }
}

/// Model card information about emotion detection
struct EmotionModelCard: Codable {
    let modelName: String
    let modelVersion: String
    let lastUpdated: Date
    let accuracyMetrics: AccuracyMetrics
    let limitations: [String]
    let neurodiversityConsiderations: [String]
    let dataSources: [String]

    struct AccuracyMetrics: Codable {
        let overallAccuracy: Double          // 0-1
        let joyAccuracy: Double
        let calmAccuracy: Double
        let frustrationAccuracy: Double
        let overwhelmAccuracy: Double
        let focusedAccuracy: Double
        let dysregulatedAccuracy: Double

        var formattedOverall: String {
            return "\(Int(overallAccuracy * 100))%"
        }
    }

    static var current: EmotionModelCard {
        return EmotionModelCard(
            modelName: "attune Emotion Classifier",
            modelVersion: "1.0.0",
            lastUpdated: Date(),
            accuracyMetrics: AccuracyMetrics(
                overallAccuracy: 0.72,
                joyAccuracy: 0.85,
                calmAccuracy: 0.78,
                frustrationAccuracy: 0.68,
                overwhelmAccuracy: 0.65,
                focusedAccuracy: 0.70,
                dysregulatedAccuracy: 0.60
            ),
            limitations: [
                "Not a diagnostic tool - for supportive guidance only",
                "Accuracy varies based on lighting and camera angle",
                "May be less accurate with partial face occlusion",
                "Individual children have unique expression patterns",
                "Requires calibration period (3-5 sessions) for best results"
            ],
            neurodiversityConsiderations: [
                "Trained on neurodivergent facial expressions",
                "Does not penalize flat affect or atypical expressions",
                "Respects stimming as valid emotional expression",
                "Adapts to individual expression patterns via parent validation",
                "Always shows confidence level - never presents as certain diagnosis"
            ],
            dataSources: [
                "Diverse dataset of neurodivergent children (ages 2-8)",
                "Parent-validated emotion labels",
                "Multiple cultural backgrounds and expression styles",
                "On-device learning from your child's unique patterns"
            ]
        )
    }
}
