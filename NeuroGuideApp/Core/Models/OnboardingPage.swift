//
//  OnboardingPage.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//

import Foundation

/// Represents a single page in the onboarding tutorial
struct OnboardingPage: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String // SF Symbol name
    let featureType: FeatureType

    enum FeatureType: String {
        case welcome
        case liveCoach
        case emotionInterface
        case askNeuroGuide
        case childProfile
    }

    // MARK: - Predefined Pages

    static let welcome = OnboardingPage(
        id: "welcome",
        title: "Welcome to attune",
        description: "Supporting you on your parenting journey with compassionate, neurodiversity-affirming guidance",
        iconName: "heart.circle.fill",
        featureType: .welcome
    )

    static let liveCoach = OnboardingPage(
        id: "live_coach",
        title: "Live Coach",
        description: "Real-time support during challenging moments, with suggestions that respect your child's unique way of being",
        iconName: "figure.walk",
        featureType: .liveCoach
    )

    static let emotionInterface = OnboardingPage(
        id: "emotion_interface",
        title: "Emotion Check",
        description: "Understand emotional context without judgment or labels, honoring neurodivergent expressions",
        iconName: "heart.circle",
        featureType: .emotionInterface
    )

    static let askNeuroGuide = OnboardingPage(
        id: "ask_neuroguide",
        title: "Ask attune",
        description: "Get evidence-based answers to your questions, grounded in neurodiversity-affirming practices",
        iconName: "questionmark.circle.fill",
        featureType: .askNeuroGuide
    )

    static let childProfile = OnboardingPage(
        id: "child_profile",
        title: "Personalized Support",
        description: "Create a profile that respects your child's sensory preferences, communication style, and individual strengths",
        iconName: "person.circle.fill",
        featureType: .childProfile
    )

    /// All onboarding pages in order
    static let allPages: [OnboardingPage] = [
        .welcome,
        .liveCoach,
        .emotionInterface,
        .askNeuroGuide,
        .childProfile
    ]
}
