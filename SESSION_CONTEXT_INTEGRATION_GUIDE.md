# Session Context Integration Guide

This guide shows how to integrate session history and behavior trends into your Live Coach LLM prompts.

## Overview

The enhanced prompt now includes:
- **Child profile** (diagnosis, triggers, effective strategies)
- **Session duration** and behavior trends
- **Arousal timeline** (recent observations)
- **Detected patterns** (escalation, cycling, stable regulation)
- **Previous suggestions** (to avoid repetition)
- **Co-regulation moments** (parent-child interactions)

## Integration Steps

### 1. Update LiveCoachViewModel

Add SessionContext tracking to your LiveCoachViewModel:

```swift
// In LiveCoachViewModel.swift

class LiveCoachViewModel: ObservableObject {
    // Existing properties...

    // Add session context tracking
    @Published private var sessionContext: SessionContext?
    private var sessionStartTime: Date?

    // MARK: - Session Start

    func startSession() async {
        // Existing session start code...

        // Initialize session context
        let profile = try? await ChildProfileManager.shared.getProfile()
        sessionContext = SessionContext.initial(childProfile: profile)
        sessionStartTime = Date()

        print("✅ Session context initialized")
    }

    // MARK: - Update Arousal Band

    func updateArousalBandWithStabilization(...) async {
        // Existing code...

        // Update session context with arousal observation
        sessionContext?.addArousalObservation(band: band)

        // Update session duration
        if let startTime = sessionStartTime {
            let minutes = Int(Date().timeIntervalSince(startTime) / 60)
            sessionContext?.updateDuration(minutes)
        }

        // Update suggestions...
    }

    // MARK: - Generate Suggestions

    private func updateSuggestions(
        arousalBand: ArousalBand,
        analysis: SessionAnalysisResult
    ) async {
        // Call LLM with session context
        let newSuggestions = await llmCoachingService.generateSuggestionsWithResources(
            arousalBand: arousalBand,
            behaviors: analysis.childBehaviors,
            environmentContext: analysis.environmentContext,
            parentStress: analysis.parentStressLevel,
            childName: currentChildProfile?.name,
            sessionContext: sessionContext  // ⬅️ Pass session context
        )

        // Update session context with delivered suggestions
        for suggestion in newSuggestions {
            sessionContext?.addSuggestion(suggestion.text)
        }

        // Update UI
        await MainActor.run {
            self.suggestionsWithResources = newSuggestions
        }
    }

    // MARK: - Co-Regulation Events

    func recordCoRegulationEvent(_ event: CoRegulationEvent) {
        // Existing code...

        // Add to session context
        let description: String
        switch event.type {
        case .calming:
            description = "Parent calming interaction - child responded positively"
        case .engaging:
            description = "Parent engagement - child showing connection"
        case .modeling:
            description = "Parent modeling regulation - child observing"
        }

        sessionContext?.addCoRegulationEvent(description)
    }
}
```

### 2. Example: Full Integration Flow

```swift
// When session starts
func startSession() async {
    isSessionActive = true
    sessionStartTime = Date()

    // Load child profile
    currentChildProfile = try? await profileManager.getProfile()

    // Initialize session context with profile
    sessionContext = SessionContext.initial(childProfile: currentChildProfile)

    // Start camera, audio, etc...
}

// Every time you update arousal band (every ~20 seconds)
func processFrame(_ videoFrame: CVPixelBuffer) async {
    // Analyze frame...
    let analysis = await mlIntegration.analyzeFrame(...)

    // Update arousal band
    await updateArousalBandWithStabilization(
        band: analysis.arousalBand,
        suggestions: analysis.suggestions,
        suggestionsWithResources: analysis.suggestionsWithResources
    )

    // Inside updateArousalBandWithStabilization:
    // 1. Add observation to session context
    sessionContext?.addArousalObservation(band: band)

    // 2. Update duration
    if let start = sessionStartTime {
        let minutes = Int(Date().timeIntervalSince(start) / 60)
        sessionContext?.updateDuration(minutes)
    }

    // 3. Generate new suggestions with context
    let suggestions = await llmCoachingService.generateSuggestionsWithResources(
        arousalBand: band,
        behaviors: behaviors,
        environmentContext: environment,
        parentStress: parentStress,
        childName: currentChildProfile?.name,
        sessionContext: sessionContext  // ⬅️ Includes full session history
    )

    // 4. Add delivered suggestions to context
    for suggestion in suggestions {
        sessionContext?.addSuggestion(suggestion.text)
    }
}

// When co-regulation events happen
func onCoRegulationDetected(event: CoRegulationEvent) {
    sessionContext?.addCoRegulationEvent(
        "Parent-child connection moment: \(event.type.displayName)"
    )
}
```

## What the LLM Now Sees

### Before (No Session Context)
```
Clinical Assessment:
- Arousal regulation state: Yellow Zone (Mild Dysregulation)
- Observable behaviors: Increased movement, vocal changes
- Environmental factors: moderate lighting, moderate noise
- Caregiver stress indicators: moderate

Provide 3 recommendations...
```

### After (With Session Context)
```
You are a compassionate neurodiversity-affirming coach...

CHILD PROFILE:
- Name: Emma, Age: 5
- Diagnosis: Autism Spectrum Disorder
- Communication: Verbal with some difficulties
- Known triggers: Loud noises, transitions, crowded spaces
- Effective strategies: Deep pressure, quiet space, visual schedules

SESSION CONTEXT:
- Duration: 8 minutes
- Behavior trend: Escalating - moved from regulated toward dysregulated state

AROUSAL TIMELINE (Recent observations):
20s ago: Green Zone
40s ago: Green Zone
60s ago: Yellow Zone
80s ago: Yellow Zone
100s ago: Red Zone
120s ago: Yellow Zone

PATTERNS OBSERVED THIS SESSION:
• Rapid cycling between arousal states
• Frequent transitions between states (may indicate sensory seeking or environmental triggers)

PREVIOUS SUGGESTIONS (avoid repeating):
1. Lower the lights and reduce background noise to minimize sensory input
2. Offer a weighted blanket or deep pressure for calming
3. Take three deep breaths yourself to model regulation

CO-REGULATION MOMENTS:
08:45: Parent calming interaction - child responded positively
08:30: Parent modeling regulation - child observing

CURRENT SITUATION:
- Arousal state: Yellow Zone (Mild Dysregulation)
- Observable behaviors: Increased movement, vocal changes
- Environment: moderate lighting, moderate noise
- Parent stress level: moderate

Based on:
1. Emma's known profile (responds well to deep pressure, struggles with noise)
2. The session shows escalation with rapid state changes
3. Previous suggestions about sensory reduction and deep pressure were given
4. Trajectory is concerning (escalating pattern)
5. Parent has been successfully co-regulating

Provide 3 specific, actionable coaching suggestions that:
- Build on the successful co-regulation moments
- Adapt if previous strategies need adjustment
- Address the escalating pattern observed
...
```

## Key Benefits

### 1. **Context-Aware Suggestions**
- LLM knows what's already been tried
- Can adapt if previous suggestions didn't work
- Builds on what's working

### 2. **Pattern Recognition**
- Detects escalation early: "I notice Emma is escalating despite sensory adjustments..."
- Recognizes improvement: "Great progress! Emma is stabilizing. Let's maintain..."
- Identifies cycles: "Emma is cycling between states - may need transition support..."

### 3. **Personalization**
- Uses child's name
- References known triggers and effective strategies
- Considers diagnosis-specific needs

### 4. **Avoids Repetition**
- Won't suggest the same thing twice in quick succession
- Unless it's to reinforce something that's working

### 5. **Acknowledges Progress**
- Recognizes co-regulation success
- Affirms parent efforts
- Adjusts tone based on trajectory

## Best Practices

### 1. Update Context Regularly
```swift
// Every time arousal band changes (every ~20 seconds)
sessionContext?.addArousalObservation(band: currentBand)
```

### 2. Track Delivered Suggestions
```swift
// After showing suggestions to parent
for suggestion in deliveredSuggestions {
    sessionContext?.addSuggestion(suggestion.text)
}
```

### 3. Record Co-Regulation
```swift
// When parent-child positive interactions detected
sessionContext?.addCoRegulationEvent(description)
```

### 4. Update Duration
```swift
// Periodically (every minute or with each frame)
let minutes = Int(Date().timeIntervalSince(sessionStartTime) / 60)
sessionContext?.updateDuration(minutes)
```

## Model Recommendation

For best results with session context:

- **Real-time suggestions**: `llama-3.1-8b-instant` (fast, handles context well)
- **Deep analysis**: `llama-3.1-70b-versatile` (better reasoning about patterns)

Update Groq model in LLMCoachingService.swift:
```swift
private let groqModel = "llama-3.1-8b-instant"  // Current
// OR for better reasoning:
private let groqModel = "llama-3.1-70b-versatile"  // Slower but smarter
```

## Testing

To verify it's working:

1. Start a Live Coach session
2. Check logs for: `✅ Session context initialized`
3. After 2-3 minutes, check that:
   - Arousal timeline has entries
   - Patterns are being detected
   - Suggestions reference previous ones
4. Look for LLM responses that mention:
   - "Based on the session so far..."
   - "I notice [child name] is..."
   - "You've been doing great with..."
   - "Let's try a different approach since..."

## Troubleshooting

### SessionContext is nil
- Ensure `startSession()` initializes it
- Check that profile loads successfully

### Timeline is empty
- Verify `addArousalObservation()` is called every frame
- Check that observations aren't being cleared

### Patterns not detecting
- Need at least 5 observations (>1.5 minutes)
- Patterns update automatically via `updatePatterns()`

### Suggestions still repeat
- Ensure suggestions are added to context after delivery
- Check `recentSuggestions` array is populated

---

Your Live Coach is now session-aware and will provide contextually intelligent suggestions! 🎉
