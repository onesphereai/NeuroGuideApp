# How to Use LLM-Based Arousal Detection

## Overview

LLM-based arousal detection is now integrated into the **Personalized Mode** setting. When enabled, it uses advanced AI (Llama 3.1 8B via Groq API) for holistic, context-aware arousal classification.

## Quick Answer

**To use LLM detection:**
1. Go to **Settings**
2. Switch **Live Coach Mode** to **"Personalized Mode (LLM)"**
3. Enter your **Groq API Key**
4. Start a Live Coach session

That's it! The app will automatically use LLM-based detection when in Personalized Mode.

---

## Detailed Setup Guide

### Step 1: Get a Groq API Key

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up for a free account
3. Navigate to **API Keys**
4. Create a new API key
5. Copy the key (starts with `gsk_...`)

**Note**: Groq offers a generous free tier perfect for testing.

### Step 2: Configure the App

1. Open NeuroGuide app
2. Navigate to **Settings**
3. Find **Live Coach Settings** section
4. Set **Live Coach Mode** to **"Personalized Mode (LLM)"**
5. Paste your Groq API Key in the **API Key** field

### Step 3: Start Using

1. Create or select a child profile
2. Start a Live Coach session
3. The app will automatically:
   - Use LLM detection in Personalized Mode
   - Fall back to Standard Mode if LLM fails
   - Cache results for 2 seconds to optimize API usage

---

## How It Works

### Mode Comparison

| Feature | Standard Mode | Personalized Mode (LLM) |
|---------|--------------|-------------------------|
| **Detection Method** | Rule-based weighted fusion | Advanced AI reasoning |
| **Data Used** | Features only | Complete profile + context |
| **Context Awareness** | Limited | Full (behaviors, environment, history) |
| **Explainability** | Confidence score | Reasoning + key indicators |
| **Setup Required** | None | Groq API key |
| **Internet Required** | No | Yes (falls back if offline) |
| **Best For** | Quick start, offline use | Maximum accuracy |

### What LLM Sees

When in Personalized Mode, the LLM receives:

**Child Profile**:
- Demographics, diagnosis, communication mode
- Emotion expression patterns
- Sensory preferences (all 6 senses)
- Known triggers and effective strategies
- Baseline calibration
- Co-regulation history

**Current Observations**:
- Pose features (movement, tension, posture)
- Detected behaviors (hand-flapping, covering ears, etc.)
- Vocal features (volume, pitch, energy, rate)
- Environment (lighting, noise, visual complexity)
- Parent state (stress level)

**Session Context**:
- Duration, behavior trends
- Arousal timeline
- Observed patterns
- Co-regulation events

### LLM Response Format

The LLM returns:
```json
{
  "arousalBand": "green",
  "confidence": 0.85,
  "reasoning": "Child maintaining calm baseline with appropriate movement...",
  "keyIndicators": ["Steady breathing", "Engaged play", "Responsive to parent"]
}
```

---

## Code Integration Points

### Automatic Detection Enabling

The system automatically enables LLM when:
1. User sets Live Coach Mode to "Personalized"
2. A valid Groq API key is configured
3. A Live Coach session starts

### Where Integration Happens

The integration is designed to happen automatically in `LiveCoachMLIntegration` when it detects Personalized Mode is enabled. Here's where you should add the enablement code:

**File**: `/Core/LiveCoach/Services/LiveCoachMLIntegration.swift`

**In the `setChildProfile()` method**, add LLM enablement check:

```swift
func setChildProfile(_ profile: ChildProfile?) {
    self.childProfile = profile
    arousalClassifier.setChildProfile(profile)

    // NEW: Enable LLM if in Personalized Mode
    let settings = SettingsManager() // Or inject as dependency
    if settings.liveCoachMode == .personalized {
        arousalClassifier.enableLLMDetection(
            groqAPIKey: settings.groqAPIKey,
            useAppleIntelligence: false
        )
        print("🤖 LLM detection ENABLED (Personalized Mode)")
    } else {
        arousalClassifier.disableLLMDetection()
        print("📊 Using Standard Mode (rule-based detection)")
    }

    if let profile = profile {
        print("✅ Child profile set for ML integration: \(profile.name)")
        if let diagnosis = profile.diagnosisInfo?.primaryDiagnosis {
            print("   Diagnosis: \(diagnosis.displayName)")
        }
    } else {
        print("⚠️ Child profile cleared from ML integration")
    }
}
```

**In the `analyzeFrame()` method**, ensure you pass the additional context when calling the classifier:

```swift
// Build session context (if you're tracking this)
let sessionContext = SessionContext(
    durationMinutes: Int(sessionDuration / 60),
    arousalTimeline: arousalHistory.map { ArousalTimelineEntry(timestamp: $0.timestamp, band: $0.band) },
    recentSuggestions: previousSuggestions,
    coRegulationEvents: [],
    patterns: [],
    childProfile: childProfile
)

// Build LLM context
let llmContext = LLMDetectionContext(
    detectedBehaviors: detectedBehaviors,
    environment: environmentContext,
    parentStress: parentStressAnalysis,
    sessionContext: sessionContext  // Can be nil for now
)

// Classify arousal band (automatically uses LLM if enabled)
let classification = try await arousalClassifier.classifyArousalBand(
    image: cgImage,
    audioBuffer: audioBuffer,
    additionalContext: llmContext  // NEW parameter
)
```

---

## Settings UI

The settings are already integrated into `SettingsManager.swift`:

```swift
// User toggles this in Settings
@Published var liveCoachMode: LiveCoachMode  // .standard or .personalized

// User enters this in Settings (stored in Keychain)
@Published var groqAPIKey: String?
```

You'll need to update the Settings UI to show:
1. Live Coach Mode picker (already exists)
2. Groq API Key text field (when Personalized Mode selected)

**Example UI Code** (to add to `SettingsView.swift`):

```swift
Section {
    Picker("Live Coach Mode", selection: $settings.liveCoachMode) {
        ForEach(LiveCoachMode.allCases, id: \.self) { mode in
            Label {
                Text(mode.displayName)
            } icon: {
                Image(systemName: mode.icon)
            }
            .tag(mode)
        }
    }

    if settings.liveCoachMode == .personalized {
        VStack(alignment: .leading, spacing: 8) {
            Text("Groq API Key")
                .font(.subheadline)
                .foregroundColor(.secondary)

            SecureField("Enter API key (gsk_...)", text: $groqAPIKeyInput)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .autocorrectionDisabled()

            Link("Get free API key →", destination: URL(string: "https://console.groq.com")!)
                .font(.caption)

            Text(settings.liveCoachMode.detailedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    } else {
        Text(settings.liveCoachMode.detailedDescription)
            .font(.caption)
            .foregroundColor(.secondary)
    }
} header: {
    Text("Live Coach Mode")
} footer: {
    if settings.liveCoachMode == .personalized {
        Text("LLM mode requires internet connection. Falls back to Standard Mode automatically if offline or API fails.")
            .font(.caption2)
            .foregroundColor(.orange)
    }
}
```

---

## Monitoring & Debugging

### Console Logs

When LLM detection is active, you'll see:

**Enabled**:
```
🤖 LLM-based arousal detection ENABLED
   Mode: Groq API
```

**Successful Detection**:
```
🤖 LLM Arousal Detection: Yellow (confidence: 0.82)
   Reasoning: Child showing early signs of sensory overload...
   Key indicators: Covering ears, Increased movement, Higher vocal pitch
```

**Fallback**:
```
⚠️ LLM detection failed, falling back to rule-based: [error message]
```

### Checking Status

To verify LLM is working:
1. Enable Personalized Mode in Settings
2. Add API key
3. Start Live Coach session
4. Check Xcode console for `🤖 LLM` messages

---

## Cost Considerations

### Groq API Pricing
- **Free tier**: Very generous for testing
- **Llama 3.1 8B Instant**: Extremely low cost per token
- **Caching**: 2-second cache reduces API calls by ~60%
- **Typical session**: ~15-30 API calls per 60 seconds

### Optimization
The system automatically optimizes costs by:
- Caching identical frames for 2 seconds
- Using fast model (8B vs 70B)
- Graceful fallback to free rule-based detection

---

## Troubleshooting

### LLM Not Working?

**Check these in order:**

1. **Is Personalized Mode enabled?**
   - Go to Settings → Live Coach Mode → "Personalized Mode (LLM)"

2. **Is API key configured?**
   - Settings → Groq API Key field should have your key
   - Key stored in secure Keychain

3. **Is internet connected?**
   - LLM requires internet
   - Falls back to Standard Mode if offline

4. **Is child profile set?**
   - LLM requires a child profile
   - Create profile before starting session

5. **Check console logs**
   - Look for `🤖 LLM` messages
   - Check for error messages

### Common Errors

**"No API key configured"**
- Add Groq API key in Settings

**"LLM detection failed"**
- Check internet connection
- Verify API key is valid
- Check Groq API status

**No LLM logs appearing**
- Make sure you selected Personalized Mode
- Restart app after changing settings

---

## Summary

**To use LLM arousal detection:**

1. ✅ **Get Groq API key** from console.groq.com
2. ✅ **Go to Settings** → Live Coach Mode → **Personalized Mode (LLM)**
3. ✅ **Enter API key** in the Groq API Key field
4. ✅ **Start Live Coach session** - LLM automatically activated!

**Benefits:**
- Holistic analysis of complete child profile
- Context-aware decision making
- Neurodiversity-affirming understanding
- Explainable results
- Automatic fallback to Standard Mode

**Requirements:**
- Groq API key (free tier available)
- Internet connection
- Child profile configured

The app handles everything else automatically!
