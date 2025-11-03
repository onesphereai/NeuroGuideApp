# AI-DLC Unit 7: Multi-Tier Arousal Display System

**Implementation Date:** October 31, 2025
**Status:** 🚧 IN PROGRESS
**Unit:** Unit 7 - UX Optimization (Multi-Tier Arousal Display)

---

## 📋 Overview

Implementing a multi-tier display system that separates **awareness** (fast) from **actionable information** (slow, stable) to reduce cognitive load on parents and prevent over-reaction to momentary fluctuations.

### Problem Statement

Current single-tier display updates every frame (~3 Hz), causing:
- **Information overload** - Parents constantly reading changing text
- **False alarms** - Momentary spikes trigger unnecessary interventions
- **Decision paralysis** - Too much rapidly changing data to act on
- **Anxiety** - Fast changes feel urgent even when child is stable

### Solution: Two-Tier Architecture

**Tier 1: Ambient Awareness (3 Hz)**
- Subtle visual feedback that system is working
- No text, no numbers - pure ambient color
- Peripheral vision monitoring

**Tier 2: Actionable Information (15-30s updates)**
- Clear, stable band name and description
- Only updates when band SUSTAINS
- Designed for conscious decision-making

---

## 🎯 Design Specifications

### Tier 1: Real-Time Ambient Indicator

**Purpose:** Peripheral awareness that child is being monitored

**Visual Design:**
```
┌─────────────────────────┐
│                         │
│   [Child Camera Feed]   │  ← Subtle colored glow/pulse
│                         │     around border
│                         │
└─────────────────────────┘
     ↑
   Smooth color
   transitions
   (no flashing)
```

**Technical Requirements:**
- Update frequency: ~3 Hz (every 333ms)
- Color interpolation between bands (smooth gradients)
- Pulse animation: gentle scale/opacity modulation
- NO text overlays on this tier
- GPU-accelerated (SwiftUI animations)

**Color Mapping:**
- Shutdown: Deep blue (#1E3A8A) with slow pulse
- Green: Soft green (#10B981) with steady glow
- Yellow: Warm amber (#F59E0B) with subtle pulse
- Orange: Coral orange (#F97316) with moderate pulse
- Red: Alert red (#EF4444) with stronger pulse

**Animation Parameters:**
```swift
struct AmbientIndicatorConfig {
    let updateFrequency: TimeInterval = 0.333  // 3 Hz
    let colorTransitionDuration: TimeInterval = 1.0  // Smooth blend
    let pulseAmplitude: CGFloat = 0.05  // Subtle 5% scale change
    let pulseFrequency: TimeInterval = 2.0  // 0.5 Hz pulse
}
```

---

### Tier 2: Stabilized Actionable Display

**Purpose:** Clear, stable information for parent decision-making

**Visual Design:**
```
┌─────────────────────────────────────┐
│                                     │
│          🟢 Green Zone             │  ← Large, clear text
│                                     │
│      Calm and regulated            │  ← Brief description
│                                     │
│  Your child is in their optimal    │
│  arousal zone for learning.        │
│                                     │
└─────────────────────────────────────┘
```

**Technical Requirements:**
- Update only when band sustains for **15-30 seconds**
- Hysteresis: Different thresholds for entering vs exiting band
- Smooth fade transitions (not instant text changes)
- Larger font, high contrast, easy to read at a glance

**State Machine:**
```
Current Band: Green (15s)
  ↓ Detect Yellow readings
Buffering... (need 15s consecutive)
  ↓ Yellow sustained 15s
Transition Animation (1s fade)
  ↓
New Display: Yellow Zone
```

**Sustainability Logic:**
```swift
class StabilizedBandTracker {
    private var sustainThreshold: TimeInterval = 20.0  // 20 seconds
    private var currentBand: ArousalBand?
    private var candidateBand: ArousalBand?
    private var candidateStartTime: Date?

    func update(band: ArousalBand) -> ArousalBand? {
        if band == candidateBand {
            // Same candidate, check duration
            if let start = candidateStartTime,
               Date().timeIntervalSince(start) >= sustainThreshold {
                // Band has sustained, update display
                currentBand = candidateBand
                candidateBand = nil
                return currentBand
            }
        } else {
            // New band detected, start tracking
            candidateBand = band
            candidateStartTime = Date()
        }

        // No change in display
        return currentBand
    }
}
```

---

## 🏗️ Architecture

### Component Breakdown

```
LiveCoachView
├── Tier 1: AmbientArousalIndicator
│   ├── Real-time updates (3 Hz)
│   ├── Color interpolation
│   └── Pulse animation
│
└── Tier 2: StabilizedBandDisplay
    ├── Text-based info card
    ├── 15-30s sustain filter
    └── Smooth transitions
```

### Data Flow

```
ArousalBandClassifier (3 Hz)
    ↓
LiveCoachViewModel
    ├─→ currentArousalBand (instant)  → Tier 1 Indicator
    └─→ stabilizedArousalBand (15-30s) → Tier 2 Display
```

### New ViewModel Properties

```swift
@MainActor
class LiveCoachViewModel: ObservableObject {
    // Existing
    @Published var currentArousalBand: ArousalBand?

    // NEW: Tier 2 - Stabilized band
    @Published var stabilizedArousalBand: ArousalBand?

    // NEW: Tracking logic
    private let bandStabilizer = StabilizedBandTracker(
        sustainThreshold: 20.0  // 20 seconds
    )

    func updateArousalBand(_ band: ArousalBand) {
        // Tier 1: Immediate update
        self.currentArousalBand = band

        // Tier 2: Stabilized update
        if let stabilized = bandStabilizer.update(band: band) {
            self.stabilizedArousalBand = stabilized
        }
    }
}
```

---

## 🎨 UI Components

### Component 1: AmbientArousalIndicator

**Location:** New file `AmbientArousalIndicator.swift`

```swift
struct AmbientArousalIndicator: View {
    let arousalBand: ArousalBand?
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(bandColor, lineWidth: 4)
            .opacity(0.3 + 0.2 * sin(pulsePhase))
            .scaleEffect(1.0 + 0.02 * sin(pulsePhase))
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: pulsePhase)
            .onAppear {
                pulsePhase = .pi * 2  // Start animation
            }
    }

    var bandColor: Color {
        switch arousalBand {
        case .shutdown: return Color(hex: "1E3A8A")
        case .green: return Color(hex: "10B981")
        case .yellow: return Color(hex: "F59E0B")
        case .orange: return Color(hex: "F97316")
        case .red: return Color(hex: "EF4444")
        case .none: return .gray
        }
    }
}
```

**Usage in LiveCoachView:**
```swift
ZStack {
    CameraPreviewView(session: session)

    // Tier 1: Ambient indicator overlay
    AmbientArousalIndicator(arousalBand: viewModel.currentArousalBand)
}
```

---

### Component 2: StabilizedBandDisplay

**Location:** New file `StabilizedBandDisplay.swift`

```swift
struct StabilizedBandDisplay: View {
    let band: ArousalBand?
    @State private var displayedBand: ArousalBand? = nil

    var body: some View {
        if let displayBand = displayedBand {
            VStack(spacing: 16) {
                // Emoji/Icon
                Text(displayBand.emoji)
                    .font(.system(size: 48))

                // Band name
                Text(displayBand.displayName)
                    .font(.title.bold())
                    .foregroundColor(displayBand.color)

                // Description
                Text(displayBand.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(displayBand.color.opacity(0.1))
            )
            .transition(.opacity.combined(with: .scale))
        }
    }

    // Smooth transition when band changes
    .onChange(of: band) { newBand in
        withAnimation(.easeInOut(duration: 1.0)) {
            displayedBand = newBand
        }
    }
}
```

**Enhanced ArousalBand Model:**
```swift
extension ArousalBand {
    var emoji: String {
        switch self {
        case .shutdown: return "😴"
        case .green: return "🟢"
        case .yellow: return "🟡"
        case .orange: return "🟠"
        case .red: return "🔴"
        }
    }

    var description: String {
        switch self {
        case .shutdown:
            return "Very low arousal. Child may need gentle engagement."
        case .green:
            return "Calm and regulated. Optimal for learning and interaction."
        case .yellow:
            return "Slightly elevated arousal. Monitor for early signs."
        case .orange:
            return "Heightened arousal. Consider calming strategies."
        case .red:
            return "High arousal. Prioritize safety and co-regulation."
        }
    }
}
```

---

## 🧪 Testing Requirements

### Unit Tests

**StabilizedBandTrackerTests.swift**
```swift
class StabilizedBandTrackerTests: XCTestCase {
    func testBandMustSustainBeforeUpdate() {
        let tracker = StabilizedBandTracker(sustainThreshold: 20.0)

        // Initial state
        XCTAssertNil(tracker.update(band: .green))

        // Advance time 10s (not enough)
        advanceTime(by: 10.0)
        XCTAssertNil(tracker.update(band: .green))

        // Advance time 20s total (threshold met)
        advanceTime(by: 10.0)
        XCTAssertEqual(tracker.update(band: .green), .green)
    }

    func testFlickeringBandDoesNotUpdate() {
        let tracker = StabilizedBandTracker(sustainThreshold: 20.0)

        // Green for 10s
        advanceTime(by: 10.0)
        tracker.update(band: .green)

        // Yellow for 5s
        advanceTime(by: 5.0)
        tracker.update(band: .yellow)

        // Back to green (resets timer)
        tracker.update(band: .green)

        // Should not have updated yet
        XCTAssertNil(tracker.currentBand)
    }
}
```

---

### User Testing Scenarios

**Scenario 1: Child Momentarily Moves**
- Child in green zone
- Gets up to get toy (15s yellow)
- Returns to calm (green)
- **Expected:** Tier 1 shows color change, Tier 2 stays "Green Zone"

**Scenario 2: Sustained Transition**
- Child in green for 5 minutes
- Gradually escalates (20s yellow, 30s orange)
- **Expected:** Tier 1 tracks smoothly, Tier 2 updates after yellow sustains 20s

**Scenario 3: Rapid Fluctuations**
- Child alternating green/yellow every 5 seconds (playing energetically)
- **Expected:** Tier 1 shows fluctuations, Tier 2 stable on last sustained band

---

## 📊 Performance Considerations

### Tier 1 Optimization

- Use `@State` for animation phase (not ViewModel)
- GPU-accelerated SwiftUI modifiers (`.opacity`, `.scaleEffect`)
- Avoid heavy frame-by-frame updates

### Tier 2 Optimization

- Only re-render on sustained band change (rare)
- Pre-compute descriptions (constant strings)
- Use `.transition` for smooth animations

### Memory

- Minimal overhead: 2 timers + 1 tracking object
- No video/audio buffering for this feature
- Estimated: <1 MB additional memory

---

## 🎓 UX Research Basis

### Cognitive Load Theory (Sweller, 1988)

**Problem:** Real-time data streams exceed working memory capacity (7±2 items)

**Solution:** Two-channel processing
- **Ambient channel:** Pre-attentive visual processing (color, movement)
- **Focal channel:** Conscious text reading and decision-making

### Change Blindness (Simons & Rensink, 2005)

**Problem:** Humans miss rapid changes when attention is divided

**Solution:** Stabilized display ensures parents notice important transitions

### Fitts's Law & Target Stability

**Problem:** Moving targets are harder to interpret and act on

**Solution:** Tier 2 provides stable "target" for parent to focus on and respond to

---

## 🚀 Implementation Plan

### Phase 1: Core Logic (Day 1)
- [ ] Create `StabilizedBandTracker.swift`
- [ ] Add `stabilizedArousalBand` to `LiveCoachViewModel`
- [ ] Implement sustain threshold logic
- [ ] Unit tests for tracker

### Phase 2: Tier 1 UI (Day 1-2)
- [ ] Create `AmbientArousalIndicator.swift`
- [ ] Implement color interpolation
- [ ] Add pulse animation
- [ ] Integrate into `LiveCoachView`

### Phase 3: Tier 2 UI (Day 2)
- [ ] Create `StabilizedBandDisplay.swift`
- [ ] Add ArousalBand extensions (emoji, description)
- [ ] Implement smooth transitions
- [ ] Position in layout

### Phase 4: Polish & Testing (Day 3)
- [ ] User testing with parents
- [ ] Adjust sustain threshold based on feedback
- [ ] Performance profiling
- [ ] Accessibility improvements

---

## 📈 Success Metrics

### Quantitative
- Reduced false intervention rate by 60%
- Parent decision time reduced by 40%
- System feels "calmer" (user survey)

### Qualitative
- Parents report less anxiety
- Increased trust in system accuracy
- More confident interventions

---

## 🔄 Future Enhancements

### Adaptive Thresholds
- Learn optimal sustain duration per child
- Shorter threshold for rapid escalators
- Longer threshold for naturally active children

### Tier 3: Historical Context
- Show last 5 minutes of band history as timeline
- Update every 60 seconds
- Helps parents see patterns

### Haptic Feedback
- Gentle vibration on sustained band change
- Allows parent to monitor without looking at screen

---

## 📚 References

- Sweller, J. (1988). Cognitive load during problem solving. *Cognitive Science*, 12(2), 257-285.
- Simons, D. J., & Rensink, R. A. (2005). Change blindness: Past, present, and future. *Trends in Cognitive Sciences*, 9(1), 16-20.
- Fitts, P. M. (1954). The information capacity of the human motor system. *Journal of Experimental Psychology*, 47(6), 381-391.

---

## ✅ Status

**Current:** 🚧 Architecture designed, ready for implementation
**Next:** Implement `StabilizedBandTracker` and Tier 1 indicator

---

*Multi-tier display system designed to reduce cognitive load while maintaining awareness.*
