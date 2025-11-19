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
        self.parentSelfRegulation = []
        self.parentSelfRegulationOther = nil
        self.communicationApproach = nil
        self.communicationApproachOther = nil
        self.physicalProximityPreference = nil
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

enum CoRegulationPractice: String, Codable, CaseIterable {
    case stayCalmPresent = "Stay calm and present"
    case calmingVoice = "Use calming voice/tone"
    case physicalComfort = "Offer physical comfort (hugs, hand-holding)"
    case sensoryTools = "Provide sensory tools (weighted blanket, fidgets)"
    case quietSpace = "Create quiet space"
    case followLead = "Follow their lead"
    case other = "Other"
}

enum ParentSelfRegulationStrategy: String, Codable, CaseIterable {
    case deepBreaths = "Take deep breaths"
    case stepAway = "Step away briefly if safe"
    case groundingTechniques = "Use grounding techniques"
    case remindTemporary = "Remind myself this is temporary"
    case seekSupport = "Seek support from partner/family"
    case struggle = "I struggle with this"
    case other = "Other"
}

enum CommunicationApproach: String, Codable, CaseIterable {
    case minimalVerbal = "Minimal verbal communication"
    case simpleDirectives = "Simple, calm directives"
    case noTalkingPresence = "No talking, just presence"
    case visualSupports = "Visual supports/AAC"
    case dependsSituation = "Depends on the situation"
    case other = "Other"
}

enum PhysicalProximityPreference: String, Codable, CaseIterable {
    case seekCloseness = "Seek physical closeness"
    case needSpace = "Need space/distance"
    case varies = "It varies depending on the trigger"
    case unsure = "Unsure/still learning"
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
