//
//  CalmingStrategyFactory.swift
//  NeuroGuide
//
//  Created for AT-19: Co-Regulation Q2 Rating
//  Factory to create the 17 predefined calming strategies with ML metadata
//

import Foundation

/// Factory for creating predefined calming strategies with comprehensive ML metadata
struct CalmingStrategyFactory {
    
    /// Create all 17 default calming strategies as specified in AT-19
    static func createDefaultStrategies() -> [CalmingStrategyRating] {
        return [
            deepPressure(),
            rhythmicMovement(),
            quietEnvironment(),
            noiseReduction(),
            favoriteSensoryItems(),
            cozyCalmSpace(),
            gentlePhysicalComfort(),
            breathingTogether(),
            calmVoice(),
            simpleLanguage(),
            offeringChoices(),
            predictableRoutines(),
            countdownBeforeTransitions(),
            movementBreak(),
            silentPresence(),
            preferredActivities(),
            // Note: "Other" is added dynamically by user
        ]
    }
    
    // MARK: - Individual Strategy Definitions
    
    private static func deepPressure() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Deep pressure (hugs, weighted items)",
            rating: nil,
            category: .sensoryInput,
            subtype: "Proprioceptive input",
            example: "Bear hugs, weighted blanket, firm squeezes",
            severityModulation: .high,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.proprioceptive, .tactile]
        )
    }
    
    private static func rhythmicMovement() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Rhythmic movement (rocking, swaying)",
            rating: nil,
            category: .sensoryInput,
            subtype: "Vestibular input",
            example: "Rocking chair, swaying together, gentle bouncing",
            severityModulation: .moderate,
            expectedCalmingTime: .moderate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.vestibular, .proprioceptive]
        )
    }
    
    private static func quietEnvironment() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Quiet/dimmed environment",
            rating: nil,
            category: .environmental,
            subtype: "Sensory reduction",
            example: "Dim lights, close curtains, reduce ambient noise",
            severityModulation: .moderate,
            expectedCalmingTime: .moderate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .auditory]
        )
    }
    
    private static func noiseReduction() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Noise reduction (headphones, soft music)",
            rating: nil,
            category: .environmental,
            subtype: "Auditory modulation",
            example: "Noise-canceling headphones, white noise, calming playlist",
            severityModulation: .high,
            expectedCalmingTime: .immediate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.auditory]
        )
    }
    
    private static func favoriteSensoryItems() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Favorite sensory items (fidgets, chewy tools)",
            rating: nil,
            category: .sensoryInput,
            subtype: "Multi-sensory engagement",
            example: "Fidget spinner, chewy necklace, stress ball, textured toys",
            severityModulation: .moderate,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.tactile, .proprioceptive, .visual]
        )
    }
    
    private static func cozyCalmSpace() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Cozy calm space (blanket fort, tent, bean bag)",
            rating: nil,
            category: .environmental,
            subtype: "Safe retreat space",
            example: "Blanket fort, pop-up tent, bean bag corner, under table",
            severityModulation: .high,
            expectedCalmingTime: .moderate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .tactile, .proprioceptive]
        )
    }
    
    private static func gentlePhysicalComfort() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Gentle physical comfort (holding hands, sitting close)",
            rating: nil,
            category: .coRegulation,
            subtype: "Proximity and touch",
            example: "Holding hands, sitting close, gentle back rub",
            severityModulation: .moderate,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.tactile, .interoceptive]
        )
    }
    
    private static func breathingTogether() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Breathing together",
            rating: nil,
            category: .coRegulation,
            subtype: "Synchronized regulation",
            example: "Deep breaths together, belly breathing, counting breaths",
            severityModulation: .moderate,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.interoceptive, .auditory]
        )
    }
    
    private static func calmVoice() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Calm voice and tone",
            rating: nil,
            category: .communication,
            subtype: "Vocal regulation",
            example: "Soft, slow speaking; lower pitch; soothing tone",
            severityModulation: .moderate,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.auditory]
        )
    }
    
    private static func simpleLanguage() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Simple language or visual supports",
            rating: nil,
            category: .communication,
            subtype: "Communication modification",
            example: "Short phrases, visual schedule, picture cards",
            severityModulation: .high,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .auditory]
        )
    }
    
    private static func offeringChoices() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Offering choices",
            rating: nil,
            category: .communication,
            subtype: "Autonomy support",
            example: "Would you like A or B? Do you want to do X first?",
            severityModulation: .low,
            expectedCalmingTime: .immediate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.auditory]
        )
    }
    
    private static func predictableRoutines() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Predictable routines",
            rating: nil,
            category: .routine,
            subtype: "Structure and predictability",
            example: "Same order of activities, consistent schedule, routines chart",
            severityModulation: .low,
            expectedCalmingTime: .extended,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .interoceptive]
        )
    }
    
    private static func countdownBeforeTransitions() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Countdown before transitions",
            rating: nil,
            category: .transition,
            subtype: "Transition preparation",
            example: "5 minute warning, visual timer, counting down",
            severityModulation: .low,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.auditory, .visual]
        )
    }
    
    private static func movementBreak() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Movement break (jumping, running)",
            rating: nil,
            category: .movement,
            subtype: "Proprioceptive/vestibular release",
            example: "Jumping jacks, running outside, trampoline, dancing",
            severityModulation: .high,
            expectedCalmingTime: .quick,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.proprioceptive, .vestibular]
        )
    }
    
    private static func silentPresence() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Silent presence",
            rating: nil,
            category: .presence,
            subtype: "Non-verbal support",
            example: "Being nearby without talking, quiet companionship",
            severityModulation: .moderate,
            expectedCalmingTime: .moderate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .interoceptive]
        )
    }
    
    private static func preferredActivities() -> CalmingStrategyRating {
        CalmingStrategyRating(
            strategyName: "Preferred activities (drawing, Lego, etc.)",
            rating: nil,
            category: .sensoryInput,
            subtype: "Engaging redirection",
            example: "Drawing, building blocks, favorite toy, special interest",
            severityModulation: .low,
            expectedCalmingTime: .moderate,
            ageApplicability: .allAges,
            sensorySystemInvolved: [.visual, .tactile, .proprioceptive]
        )
    }
}
