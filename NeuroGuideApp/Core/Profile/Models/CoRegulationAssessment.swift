//
//  CoRegulationAssessment.swift
//  NeuroGuide
//
//  Co-regulation practices assessment for personalizing coaching
//

import Foundation

/// Assessment of parent's co-regulation practices and child's response patterns
struct CoRegulationAssessment: Codable {
    // MARK: - Question 1: Current Co-Regulation Practices
    var currentPractices: [CoRegulationPractice]
    var currentPracticesOther: String?

    // MARK: - Question 2: Effective Calming Strategies (1-5 rating)
    // NEW: Comprehensive strategy ratings (replaces individual properties)
    var strategyRatings: [CalmingStrategyRating] = []
    
    // DEPRECATED: Legacy individual properties (kept for migration)
    var deepPressureRating: Int?  // 1-5
    var rhythmicMovementRating: Int?  // 1-5
    var quietEnvironmentRating: Int?  // 1-5
    var sensoryItemsRating: Int?  // 1-5
    var routinesRating: Int?  // 1-5
    var verbalReassuranceRating: Int?  // 1-5
    var silentPresenceRating: Int?  // 1-5

    // MARK: - Question 3: Parent's Self-Regulation
    var parentSelfRegulation: [ParentSelfRegulationStrategy]
    var parentSelfRegulationOther: String?

    // MARK: - Question 4: Communication During Dysregulation
    var communicationApproach: CommunicationApproach?
    var communicationApproachOther: String?

    // MARK: - Question 5: Physical Proximity Preferences
    var physicalProximityPreference: PhysicalProximityPreference?
    var physicalProximityPreferenceOther: String?

    // MARK: - Question 6: Recovery Time Patterns
    var recoveryTime: RecoveryTime?

    // MARK: - Question 7: Post-Regulation Connection
    var postRegulationConnection: [PostRegulationBehavior]
    var postRegulationConnectionOther: String?

    // MARK: - Question 8: Parent Confidence (1-5 scale)
    var parentConfidence: Int?  // 1-5

    // MARK: - Question 9: Support Needs
    var supportNeeds: [SupportNeed]
    var supportNeedsOther: String?

    // MARK: - Question 10: Specific Scenarios (Optional)
    var morningTransitionsStrategy: String?
    var bedtimeRoutinesStrategy: String?
    var publicMeltdownsStrategy: String?
    var siblingConflictsStrategy: String?
    var unexpectedChangesStrategy: String?

    // MARK: - Metadata
    var completedAt: Date?
    var lastUpdated: Date

    init() {
        self.currentPractices = []
        self.currentPracticesOther = nil
        self.strategyRatings = CalmingStrategyFactory.createDefaultStrategies()
        self.parentSelfRegulation = []
        self.parentSelfRegulationOther = nil
        self.communicationApproach = nil
        self.communicationApproachOther = nil
        self.physicalProximityPreference = nil
        self.physicalProximityPreferenceOther = nil
        self.recoveryTime = nil
        self.postRegulationConnection = []
        self.postRegulationConnectionOther = nil
        self.supportNeeds = []
        self.supportNeedsOther = nil
        self.completedAt = nil
        self.lastUpdated = Date()
    }

    /// Check if assessment is complete (all required questions answered)
    func isComplete() -> Bool {
        return !currentPractices.isEmpty &&
               communicationApproach != nil &&
               physicalProximityPreference != nil &&
               recoveryTime != nil &&
               parentConfidence != nil
    }

    /// Mark assessment as completed
    mutating func markCompleted() {
        completedAt = Date()
        lastUpdated = Date()
    }
}

// MARK: - Supporting Enums

/// Question 1 options - Updated Nov 2025 (AT-18) to include full spectrum of parent responses
enum CoRegulationPractice: String, Codable, CaseIterable {
    // Reactive/Stressed Responses
    case raiseVoice = "I raise my voice or get frustrated"
    case walkAway = "I walk away to calm myself"
    case askToStop = "I ask them to stop or \"behave\""
    case useTimeOut = "I use time-out / ask them to go to another room"
    case tryDistract = "I try to distract them quickly"
    
    // Constructive Co-Regulation Responses
    case stayClose = "I stay close to them"
    case calmVoice = "I use a calm voice"
    case physicalComfort = "I offer physical comfort (hugs, hand-holding)"
    case nameFeelings = "I help them name their feelings"
    case guideBreathing = "I guide their breathing or help them slow down"
    case changeEnvironment = "I change the environment (dim lights, reduce noise)"
    
    // Other
    case other = "Other"
}

enum ParentSelfRegulationStrategy: String, Codable, CaseIterable {
    case deepBreaths = "Take slow, deep breaths"
    case stepAway = "Step away briefly if safe"
    case groundingTechniques = "Use grounding techniques (touch, noticing surroundings)"
    case remindMomentPass = "Remind myself this moment will pass"
    case calmingSelfTalk = "Use calming self-talk"
    case seekSupport = "Seek support from partner/family"
    case textCallSupport = "Text or call someone for support"
    case reactBeforeMean = "I react before I mean to"
    case struggleStayCalm = "I struggle to stay calm in the moment"
    case other = "Other"
}

enum CommunicationApproach: String, Codable, CaseIterable {
    case minimalVerbal = "Very little talking"
    case simpleDirectives = "Simple, calm directions"
    case noTalkingPresence = "No talking — just being present"
    case visualSupports = "Visual supports (pictures, gestures, AAC)"
    case dependsSituation = "It depends on the situation"
    case other = "Other"
}

enum PhysicalProximityPreference: String, Codable, CaseIterable {
    case seekCloseness = "They come close or seek physical comfort"
    case needSpace = "They need space or distance"
    case varies = "It varies depending on what's happening"
    case unsure = "I'm not sure / still learning"
    case other = "Other"
}

enum RecoveryTime: String, Codable, CaseIterable {
    case zeroToFive = "0-5 minutes"
    case fiveToFifteen = "5-15 minutes"
    case fifteenToThirty = "15-30 minutes"
    case thirtyPlus = "30+ minutes"
    case variesGreatly = "It varies greatly"
}

enum PostRegulationBehavior: String, Codable, CaseIterable {
    case returnsWithoutAcknowledgment = "Returns to activity without acknowledgment"
    case seeksPhysicalComfort = "Seeks physical comfort"
    case talksAboutIt = "Talks about what happened"
    case needsQuietTime = "Needs continued quiet time"
    case increasedClinginess = "Shows increased clinginess"
    case other = "Other"
}

enum SupportNeed: String, Codable, CaseIterable {
    case understandTriggers = "Understanding their triggers better"
    case moreStrategies = "More strategies to try"
    case helpRegulating = "Help regulating my own emotions"
    case supportFromOthers = "Support from others who understand"
    case knowingNormal = "Knowing what's 'normal'"
    case other = "Other"
}
