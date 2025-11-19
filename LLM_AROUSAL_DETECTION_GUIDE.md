# LLM-Based Arousal Band Detection - Implementation Guide

## Overview

This document describes the new **LLM-based arousal band detection** system that sends comprehensive multimodal data and complete child profile information to a Large Language Model (LLM) for holistic, context-aware arousal classification.

## Key Changes

### Before (Rule-Based)
- **Weighted fusion**: Pose (50%) + Facial (40%) + Vocal (10%)
- **Fixed thresholds**: Arousal score → Band mapping
- **Limited context**: Only raw feature values
- **One-size-fits-most**: Diagnosis adjustments were pre-defined multipliers

### After (LLM-Based)
- **Holistic analysis**: LLM considers ALL available data simultaneously
- **Deep personalization**: Complete child profile included (diagnosis, sensory preferences, triggers, strategies, baseline, emotion expression patterns)
- **Contextual reasoning**: Environment, behaviors, parent stress, session timeline
- **Adaptive**: LLM can reason about complex patterns and edge cases

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  LiveCoachMLIntegration                      │
│              (Captures frame + audio)                        │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│             ArousalBandClassifier.classifyArousalBand()      │
│                                                              │
│  1. Extract features (Pose, Vocal, Facial) - Concurrent     │
│  2. Check if LLM detection enabled                          │
│     ├─ YES → Build LLMArousalDetectionRequest               │
│     │         ├─ Complete ChildProfile                      │
│     │         ├─ All extracted features                     │
│     │         ├─ Detected behaviors                         │
│     │         ├─ Environment context                        │
│     │         ├─ Parent stress                              │
│     │         └─ Session timeline                           │
│     │         ↓                                              │
│     │   LLMArousalDetectionService.detectArousalBand()      │
│     │         ↓                                              │
│     │   Build comprehensive prompt with ALL data            │
│     │         ↓                                              │
│     │   Send to Groq API (Llama 3.1 8B Instant)             │
│     │         ↓                                              │
│     │   Parse JSON response                                 │
│     │   { arousalBand, confidence, reasoning, keyIndicators }│
│     │         ↓                                              │
│     │   Return (band, confidence)                           │
│     └─ On error → Fall back to rule-based                   │
│                                                              │
│     NO → Use rule-based fusion (original behavior)          │
│                                                              │
│  3. Apply temporal smoothing (5-frame history)              │
│  4. Return ArousalBandClassification                        │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

### New Files

1. **`LLMArousalDetectionService.swift`**
   - Location: `/Core/LiveCoach/Services/`
   - Purpose: Manages LLM API calls for arousal detection
   - Key methods:
     - `detectArousalBand(request:)` - Main detection method
     - `buildSystemPrompt()` - Creates neurodiversity-aware system instructions
     - `buildUserPrompt(from:)` - Builds comprehensive context prompt
     - `parseGroqResponse(data:)` - Parses LLM JSON response

2. **`LLMArousalDetectionRequest`** (struct in LLMArousalDetectionService.swift)
   - Complete request payload including:
     - Child profile (all fields)
     - Current features (pose, vocal, facial)
     - Detected behaviors
     - Environment context
     - Parent stress analysis
     - Session context (timeline, patterns)

### Modified Files

1. **`ArousalBandClassifier.swift`**
   - Location: `/Core/ML/Inference/`
   - Changes:
     - Added `llmDetectionService` property
     - Added `useLLMDetection` flag
     - New methods: `enableLLMDetection()`, `disableLLMDetection()`
     - Modified `classifyArousalBand()` to support LLM path with graceful fallback
     - Added `LLMDetectionContext` struct for additional context

## Data Sent to LLM

### 1. Child Profile (Complete)

```swift
// Basic Information
- Name, Age, Pronouns
- Diagnosis (primary + secondary)
- Communication mode & notes

// Emotion Expression Profile
- Flat affect flag
- Echolalia/scripting
- Stimming patterns (happy vs distressed)
- Alexithymia flag
- Non-speaking flag
- Custom emotion expressions for each state

// Sensory Profile
- Touch, Sound, Sight, Movement, Taste, Smell preferences
- Specific sensory triggers

// Known Triggers
- Category (sensory, social, routine, environmental)
- Description

// Effective Strategies
- Category (sensory, environmental, communication, co-regulation, transition)
- Description
- Effectiveness rating (0-5)
- Usage count

// Baseline Calibration
- Captured timestamp
- Movement energy baseline
- Common stims (and whether regulatory)
- Typical vocal pitch/volume
- Typical posture

// Co-Regulation History
- Total sessions
- Average helpfulness rating
- Strategy usage patterns
```

### 2. Current Observations

```swift
// Pose/Movement Features
- Movement intensity (0-1)
- Body tension (0-1)
- Posture openness (0-1)
- Arousal contribution score
- Detection confidence

// Detected Behaviors
- handFlapping, rocking, spinning, jumping, pacing, stillness
- coveringEars, coveringEyes, retreating, seekingPressure
- pointing, reaching, approaching
- escalating, meltdown

// Vocal Characteristics
- Volume (dB)
- Pitch (Hz)
- Energy (0-1)
- Speaking rate (syllables/sec)
- Pitch variation (jitter 0-1)
- Vocal stress classification (calm, elevated, strained, flat)
- Arousal contribution score

// Environment
- Lighting level (bright, normal, dim, flickering)
- Visual complexity (calm, moderate, cluttered)
- Noise level (quiet, moderate, loud, very loud)
- Noise type (voices, mechanical, music, traffic)
- Crowd density (solo, few people, crowded)

// Parent State (for co-regulation context)
- Overall stress level (calm, building, high)
- Facial tension (relaxed, moderate, high)
- Vocal stress (calm, elevated, strained, flat)
```

### 3. Session Context (Temporal)

```swift
// Session Timeline
- Duration (formatted as MM:SS)
- Behavior trend ("stable", "escalating", "de-escalating", "fluctuating")
- Recent arousal timeline (e.g., ["green", "green", "yellow", "orange"])

// Observed Patterns
- Free-text descriptions of patterns (e.g., "covering ears repeatedly")

// Previous Suggestions
- To avoid repetition

// Co-Regulation Moments
- Count of times parent helped child regulate
```

## LLM Prompt Design

### System Prompt (Neurodiversity-Aware)

The system prompt establishes:
1. **Expert role**: Arousal state classifier for neurodivergent children (ages 2-8)
2. **Arousal band definitions** (Polyvagal Theory-based):
   - SHUTDOWN: Under-aroused, dorsal vagal
   - GREEN: Regulated, ventral vagal
   - YELLOW: Elevated, sympathetic activation beginning
   - ORANGE: High arousal, sympathetic dominance
   - RED: Crisis, meltdown/shutdown
3. **Important considerations**:
   - Stimming can occur in BOTH regulated and dysregulated states
   - Flat affect is NORMAL for many autistic children
   - Movement differences are neurotype features
   - Context matters
   - Compare to THEIR baseline, not neurotypical norms
4. **Response format**: Structured JSON with arousalBand, confidence, reasoning, keyIndicators

### User Prompt (Comprehensive Context)

The user prompt is built dynamically and includes:
- Complete formatted child profile
- All current observations with units and context
- Session context and temporal patterns
- Clear instruction to respond with JSON only

## Response Format

The LLM returns JSON:

```json
{
  "arousalBand": "green",
  "confidence": 0.85,
  "reasoning": "Brief explanation of key factors",
  "keyIndicators": [
    "Indicator 1",
    "Indicator 2",
    "Indicator 3"
  ]
}
```

Valid arousalBand values: `"green"`, `"yellow"`, `"orange"`, `"red"`, `"shutdown"`

Confidence: 0.0-1.0

## API Configuration

### Groq API

- **Endpoint**: `https://api.groq.com/openai/v1/chat/completions`
- **Model**: `llama-3.1-8b-instant` (fast for real-time detection)
- **Temperature**: 0.3 (low for consistent classification)
- **Max tokens**: 200
- **Response format**: JSON object
- **Caching**: 2-second cache to avoid repeated calls on similar frames

### Apple Intelligence

- **Status**: Framework prepared, awaiting public API (iOS 18.1+)
- **Priority**: Apple Intelligence is tried first when available
- **Fallback**: Groq API → Enhanced rule-based

## Usage

### 1. Enable LLM Detection

```swift
// In your LiveCoach setup or settings
let classifier = ArousalBandClassifier.shared

// Option A: Using Groq API (requires API key)
classifier.enableLLMDetection(
    groqAPIKey: "your-groq-api-key",
    useAppleIntelligence: false
)

// Option B: Using Apple Intelligence (when available)
classifier.enableLLMDetection(
    groqAPIKey: nil,
    useAppleIntelligence: true
)
```

### 2. Set Child Profile

```swift
// MUST set child profile for LLM detection to work
classifier.setChildProfile(childProfile)
```

### 3. Classify with Additional Context

```swift
// When calling from LiveCoachMLIntegration
let context = LLMDetectionContext(
    detectedBehaviors: detectedBehaviors,
    environment: environmentContext,
    parentStress: parentStressAnalysis,
    sessionContext: sessionContext
)

let classification = try await classifier.classifyArousalBand(
    image: videoFrame,
    audioBuffer: audioBuffer,
    additionalContext: context  // NEW parameter
)
```

### 4. Disable LLM Detection

```swift
// Return to rule-based detection
classifier.disableLLMDetection()
```

## Integration Points

### LiveCoachMLIntegration

Modify `analyzeFrame()` method to pass additional context:

```swift
// Build session context
let sessionContext = SessionContext(
    sessionDuration: sessionManager.currentDuration,
    behaviorTrend: determineBehaviorTrend(),
    arousalTimeline: recentArousalHistory,
    observedPatterns: identifiedPatterns,
    previousSuggestions: recentSuggestions,
    coRegulationMoments: coRegulationCount
)

// Build LLM context
let llmContext = LLMDetectionContext(
    detectedBehaviors: detectedBehaviors,
    environment: environmentContext,
    parentStress: parentStressAnalysis,
    sessionContext: sessionContext
)

// Classify with context
let classification = try await classifier.classifyArousalBand(
    image: frame,
    audioBuffer: audioBuffer,
    additionalContext: llmContext
)
```

## Error Handling

The system includes graceful fallback:

1. **LLM API fails** → Fall back to rule-based detection
2. **Invalid JSON response** → Fall back to rule-based detection
3. **Network timeout** → Fall back to rule-based detection
4. **No API key configured** → Use rule-based detection

All errors are logged with clear messages.

## Performance Considerations

### Caching
- **2-second cache**: Avoids repeated LLM calls for similar consecutive frames
- **Cost optimization**: Reduces API calls and costs

### Real-time Performance
- **Model choice**: `llama-3.1-8b-instant` is optimized for speed
- **Concurrent feature extraction**: Pose, vocal, facial extracted in parallel
- **Fallback**: Rule-based detection is instant (no network latency)

### API Costs (Groq)
- **Llama 3.1 8B Instant**: Very low cost per token
- **Typical prompt size**: ~1500-2500 tokens (depending on profile completeness)
- **Response size**: ~100-150 tokens
- **With caching**: ~15-30 LLM calls per 60-second session

## Benefits Over Rule-Based Detection

1. **Holistic reasoning**: Considers ALL factors simultaneously, not just weighted features
2. **Context-aware**: Understands environmental triggers, parent stress, session patterns
3. **Neurodiversity-affirming**: Built-in understanding of autistic/ADHD/SPD presentations
4. **Personalized**: Uses complete child profile including custom emotion expressions
5. **Explainable**: Returns reasoning and key indicators
6. **Adaptive**: Can handle edge cases and complex scenarios better than fixed rules
7. **Baseline-aware**: Explicitly compares to child's personal baseline, not neurotypical norms

## Future Enhancements

1. **Apple Intelligence integration**: When API becomes available (iOS 18.1+)
2. **Fine-tuned model**: Train custom model on NeuroGuide data
3. **Multi-turn reasoning**: Allow LLM to ask clarifying questions
4. **Parent feedback loop**: Use parent confirmations to improve detection
5. **Offline mode**: On-device smaller model for privacy-first detection

## Privacy & Security

- **API calls**: Encrypted HTTPS to Groq
- **No data storage**: Groq does not store prompts (per their policy)
- **API key security**: Stored in iOS Keychain
- **Future**: On-device Apple Intelligence for complete privacy

## Testing

To test LLM detection:

1. Enable LLM with test API key
2. Set up child profile with complete data
3. Run live coach session
4. Monitor console logs for LLM detection outputs
5. Compare with rule-based detection (disable LLM to see difference)

Console logs will show:
```
🤖 LLM Arousal Detection: Yellow (confidence: 0.82)
   Reasoning: [LLM's explanation]
   Key indicators: [List of indicators]
```

## Troubleshooting

### LLM detection not working?
1. Check `useLLMDetection` flag is true
2. Verify Groq API key is configured
3. Ensure child profile is set
4. Verify additionalContext is passed
5. Check console for error messages

### Falling back to rule-based?
- Check network connection
- Verify API key validity
- Check API rate limits
- Review console error logs

### Inconsistent results?
- Check if caching is causing issues (2-second window)
- Review prompt construction
- Verify child profile data is complete
- Check feature extraction quality

---

## Summary

The new LLM-based arousal detection system provides **deep personalization** by sending comprehensive child profile data along with all captured features to an LLM for holistic, context-aware classification. It maintains **backward compatibility** with graceful fallback to rule-based detection and prioritizes **privacy** with plans for on-device Apple Intelligence integration.

This approach leverages the reasoning capabilities of LLMs to better understand the unique arousal patterns of each neurodivergent child while respecting their individual differences and baseline behaviors.
