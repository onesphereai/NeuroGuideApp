# PATENT FIGURES AND DIAGRAMS - PART 2
## NeuroGuide - Privacy-First Behavioral Analysis System

**Continuation from PATENT_FIGURES.md**
**Figures 6-15**

---

## FIGURE 6: BEHAVIORAL SPECTRUM GENERATION

### Description
Visualization of the novel personalized behavioral spectrum with child-specific color blending.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│             BEHAVIORAL SPECTRUM GENERATION ALGORITHM                 │
│          (Personalized Color-Mapped Arousal Distribution)            │
└─────────────────────────────────────────────────────────────────────┘

INPUT:
  • arousalTimeline: [ArousalBandSample] (180 samples)
  • profileColor: "#4A90E2" (Blue - child's chosen color)
  • sessionDuration: 60.0 seconds

╔═══════════════════════════════════════════════════════════════════╗
║             STEP 1: CALCULATE TIME IN EACH BAND                    ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Count Samples Per Band:                                      │
  │  ──────────────────────                                       │
  │                                                               │
  │  Shutdown:  5 samples                                         │
  │  Green:    110 samples                                        │
  │  Yellow:    45 samples                                        │
  │  Orange:    15 samples                                        │
  │  Red:        5 samples                                        │
  │  ─────────────────────                                        │
  │  Total:    180 samples                                        │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Calculate Percentages:                                       │
  │  ─────────────────────                                        │
  │  timePerSample = 60.0 / 180 = 0.333 seconds                   │
  │                                                               │
  │  Shutdown:  5 * 0.333 = 1.67s  →  2.8%                        │
  │  Green:    110 * 0.333 = 36.67s → 61.1%                       │
  │  Yellow:    45 * 0.333 = 15.0s  → 25.0%                       │
  │  Orange:    15 * 0.333 = 5.0s   →  8.3%                       │
  │  Red:        5 * 0.333 = 1.67s  →  2.8%                       │
  │  ────────────────────────────────────────                     │
  │  Total:                  60.0s → 100.0%  ✓                    │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║              STEP 2: IDENTIFY DOMINANT BAND                        ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Find Maximum:                                                │
  │  ────────────                                                 │
  │  max([2.8%, 61.1%, 25.0%, 8.3%, 2.8%]) = 61.1%               │
  │                                                               │
  │  dominantBand = Green                                         │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║         STEP 3: COLOR BLENDING WITH PROFILE COLOR                 ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Extract Profile Color RGB:                                   │
  │  ─────────────────────────                                    │
  │  profileColor = "#4A90E2"                                     │
  │               = RGB(74, 144, 226)                             │
  │               = RGB(0.29, 0.56, 0.89) [normalized 0-1]        │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Standard Arousal Band Colors:                                │
  │  ────────────────────────────                                 │
  │  Shutdown → Blue:   RGB(0, 122, 255) = (0.00, 0.48, 1.00)     │
  │  Green → Green:     RGB(52, 199, 89) = (0.20, 0.78, 0.35)     │
  │  Yellow → Yellow:   RGB(255, 204, 0) = (1.00, 0.80, 0.00)     │
  │  Orange → Orange:   RGB(255, 149, 0) = (1.00, 0.58, 0.00)     │
  │  Red → Red:         RGB(255, 59, 48) = (1.00, 0.23, 0.19)     │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Blend Each Band Color:                                       │
  │  ─────────────────────                                        │
  │  blendRatio = 0.3  (30% profile, 70% band color)              │
  │                                                               │
  │  blendedColor = profileRGB * (1 - ratio) + bandRGB * ratio    │
  │                                                               │
  │  SHUTDOWN BLEND:                                              │
  │  Profile: (0.29, 0.56, 0.89)                                  │
  │  Band:    (0.00, 0.48, 1.00)                                  │
  │  Blended: (0.29*0.7 + 0.00*0.3,                               │
  │            0.56*0.7 + 0.48*0.3,                               │
  │            0.89*0.7 + 1.00*0.3)                               │
  │         = (0.20, 0.54, 0.92)                                  │
  │         = Darker Blue                                         │
  │                                                               │
  │  GREEN BLEND:                                                 │
  │  Profile: (0.29, 0.56, 0.89)                                  │
  │  Band:    (0.20, 0.78, 0.35)                                  │
  │  Blended: (0.26, 0.63, 0.73)                                  │
  │         = Teal/Blue-Green                                     │
  │                                                               │
  │  YELLOW BLEND:                                                │
  │  Blended: (0.79, 0.63, 0.62)                                  │
  │         = Muted Yellow-Blue                                   │
  │                                                               │
  │  ORANGE BLEND:                                                │
  │  Blended: (0.79, 0.56, 0.62)                                  │
  │         = Soft Orange-Blue                                    │
  │                                                               │
  │  RED BLEND:                                                   │
  │  Blended: (0.79, 0.46, 0.58)                                  │
  │         = Purple-Red                                          │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║               STEP 4: CREATE SPECTRUM VISUALIZATION                ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Horizontal Bar Chart (Sorted by Percentage):                 │
  │  ───────────────────────────────────────────                  │
  │                                                               │
  │  ┌───────────────────────────────────────────────────┐       │
  │  │                                                   │       │
  │  │ ████████████████Green 61.1%█████████████████     │       │
  │  │ █████Yellow 25.0%█████  Orange 8.3%  Other 5.6%  │       │
  │  │                                                   │       │
  │  └───────────────────────────────────────────────────┘       │
  │                                                               │
  │  Width of each segment = percentage * totalWidth              │
  │  Color of each segment = blended color from Step 3            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

  ┌──────────────────────────────────────────────────────────────┐
  │  DETAILED SPECTRUM BAR:                                       │
  │  ─────────────────────                                        │
  │  ┌──────────────────────────────────────────────────────┐    │
  │  │ [Teal──────────Green 61%──────────Teal]              │    │
  │  │ [Muted Yellow───Yellow 25%──]                        │    │
  │  │ [Orange──8%─]                                        │    │
  │  │ [Dk Blue]                                            │    │
  │  │ [Purp]                                               │    │
  │  └──────────────────────────────────────────────────────┘    │
  │                                                               │
  │  Each color is a blend of child's profile blue (#4A90E2)     │
  │  with the standard arousal band color                         │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║                    FINAL OUTPUT                                    ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  BehaviorSpectrum:                                            │
  │  ────────────────                                             │
  │                                                               │
  │  profileColor: "#4A90E2"                                      │
  │  shutdownPercentage: 2.8%                                     │
  │  greenPercentage: 61.1%                                       │
  │  yellowPercentage: 25.0%                                      │
  │  orangePercentage: 8.3%                                       │
  │  redPercentage: 2.8%                                          │
  │  dominantBand: Green                                          │
  │                                                               │
  │  spectrumColors: [                                            │
  │    (Green, RGB(0.26, 0.63, 0.73), 61.1%),                     │
  │    (Yellow, RGB(0.79, 0.63, 0.62), 25.0%),                    │
  │    (Orange, RGB(0.79, 0.56, 0.62), 8.3%),                     │
  │    (Shutdown, RGB(0.20, 0.54, 0.92), 2.8%),                   │
  │    (Red, RGB(0.79, 0.46, 0.58), 2.8%)                         │
  │  ]                                                            │
  └──────────────────────────────────────────────────────────────┘


VISUAL EXAMPLE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For child "Emma" with profile color Blue (#4A90E2):

┌─────────────────────────────────────────────────────────────┐
│                    Emma's Behavioral Spectrum                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ███████████████████████Green Zone 61%██████████████████    │
│  █████████Yellow Zone 25%█████████                          │
│  ██████Orange 8%██████                                      │
│  ███Shutdown 3%███                                          │
│  ███Red 3%███                                               │
│                                                             │
│  Dominant State: Green (Well-Regulated)                     │
│  Session Quality: Good - mostly in green zone              │
│  Watch For: 25% yellow indicates some dysregulation        │
└─────────────────────────────────────────────────────────────┘

PARENT VIEW:
┌─────────────────────────────────────────────────────────────┐
│  Great session! Emma was regulated 61% of the time.         │
│                                                             │
│  The blue-green color shows she was calm and engaged.       │
│  The 25% yellow time suggests watching for early signs      │
│  of dysregulation in future sessions.                       │
└─────────────────────────────────────────────────────────────┘


KEY INNOVATIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. PERSONALIZATION: Each child has unique spectrum colors
2. COLOR PSYCHOLOGY: Profile color creates emotional connection
3. AT-A-GLANCE SUMMARY: Visual representation of entire session
4. PERCENTAGE-BASED: Shows proportion, not just current state
5. DOMINANT BAND: Quick identification of overall pattern
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FIGURE 7: CO-REGULATION DETECTION

### Description
Algorithm for detecting parent-child emotional synchronization patterns.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                CO-REGULATION DETECTION ALGORITHM                     │
│           (Parent-Child Emotional Synchronization)                   │
└─────────────────────────────────────────────────────────────────────┘

INPUT:
  • parentEmotionTimeline: [EmotionSample] (180 samples)
  • childArousalTimeline: [ArousalBandSample] (180 samples)
  • sessionID: UUID

╔═══════════════════════════════════════════════════════════════════╗
║                  STEP 1: TIMELINE ALIGNMENT                        ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Merge Timelines by Timestamp:                                │
  │  ────────────────────────────                                 │
  │                                                               │
  │  Parent Timeline:         Child Timeline:                     │
  │  ─────────────           ──────────────                       │
  │  0.0s: Calm              0.0s: Green                          │
  │  0.33s: Calm             0.33s: Green                         │
  │  0.66s: Regulated        0.66s: Green                         │
  │  ...                     ...                                  │
  │  20.0s: Calm             20.0s: Yellow                        │
  │  20.33s: Calm            20.33s: Yellow                       │
  │  20.66s: Calm            20.66s: Yellow                       │
  │  21.0s: Calm             21.0s: Green                         │
  │  21.33s: Calm            21.33s: Green                        │
  │  ...                     ...                                  │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Aligned Timeline:                                            │
  │  ────────────────                                             │
  │  [                                                            │
  │    { t: 0.0,  parent: Calm,  child: Green },                  │
  │    { t: 0.33, parent: Calm,  child: Green },                  │
  │    { t: 0.66, parent: Regulated, child: Green },              │
  │    ...                                                        │
  │    { t: 20.0,  parent: Calm, child: Yellow },                 │
  │    { t: 20.33, parent: Calm, child: Yellow },                 │
  │    { t: 20.66, parent: Calm, child: Yellow },                 │
  │    { t: 21.0,  parent: Calm, child: Green },  ◄── Change!     │
  │    { t: 21.33, parent: Calm, child: Green },                  │
  │    ...                                                        │
  │  ]                                                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║          STEP 2: SCAN FOR POSITIVE CO-REGULATION                   ║
║            (Parent Calm → Child Arousal Decreases)                 ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  For each 5-sample window:                                    │
  │  ─────────────────────────                                    │
  │                                                               │
  │  Window at t=20.0s (indices 60-64):                           │
  │  ────────────────────────────────                             │
  │  [                                                            │
  │    { t: 20.0,  parent: Calm, child: Yellow },  ← Start        │
  │    { t: 20.33, parent: Calm, child: Yellow },                 │
  │    { t: 20.66, parent: Calm, child: Yellow },                 │
  │    { t: 21.0,  parent: Calm, child: Green },                  │
  │    { t: 21.33, parent: Calm, child: Green }    ← End          │
  │  ]                                                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Check Condition 1: Parent Maintained Calm/Regulated          │
  │  ──────────────────────────────────────────────              │
  │  parentCalm = ALL samples have emotion in [Calm, Regulated]   │
  │  parentCalm = true ✓                                          │
  │  (All 5 samples are "Calm")                                   │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Check Condition 2: Child Arousal Decreased Significantly     │
  │  ────────────────────────────────────────────────────        │
  │  arousalScore(Yellow) = 0.5                                   │
  │  arousalScore(Green) = 0.3                                    │
  │                                                               │
  │  decrease = startScore - endScore                             │
  │           = 0.5 - 0.3                                         │
  │           = 0.2                                               │
  │                                                               │
  │  childArousalDecreased = (decrease ≥ 0.2)                     │
  │  childArousalDecreased = true ✓                               │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  BOTH CONDITIONS MET → POSITIVE CO-REGULATION DETECTED!       │
  │                                                               │
  │  Create Event:                                                │
  │  ────────────                                                 │
  │  type: PositiveCoRegulation                                   │
  │  sessionID: <session UUID>                                    │
  │  startTime: 20.0s                                             │
  │  endTime: 21.33s                                              │
  │  duration: 1.33s                                              │
  │  parentEmotionAtStart: Calm                                   │
  │  childArousalAtStart: Yellow                                  │
  │  childArousalAtEnd: Green                                     │
  │  description: "Your calm presence helped regulate your child" │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  Return this event (stop scanning)

╔═══════════════════════════════════════════════════════════════════╗
║          STEP 3: SCAN FOR NEGATIVE CO-REGULATION                   ║
║         (Parent Stressed → Child Arousal Increases)                ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Example Window at t=45.0s:                                   │
  │  ─────────────────────────                                    │
  │  [                                                            │
  │    { t: 45.0,  parent: Stressed, child: Yellow },  ← Start    │
  │    { t: 45.33, parent: Anxious,  child: Yellow },             │
  │    { t: 45.66, parent: Anxious,  child: Orange },             │
  │    { t: 46.0,  parent: Stressed, child: Orange },             │
  │    { t: 46.33, parent: Stressed, child: Orange }   ← End      │
  │  ]                                                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Check Condition 1: Parent Maintained Stressed State          │
  │  ─────────────────────────────────────────────               │
  │  stressedEmotions = [Stressed, Anxious, Frustrated,           │
  │                      Overwhelmed]                             │
  │                                                               │
  │  parentStressed = ALL samples have emotion in stressedEmotions│
  │  parentStressed = true ✓                                      │
  │  (All 5 samples are Stressed or Anxious)                      │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Check Condition 2: Child Arousal Increased Significantly     │
  │  ────────────────────────────────────────────────────        │
  │  arousalScore(Yellow) = 0.5                                   │
  │  arousalScore(Orange) = 0.7                                   │
  │                                                               │
  │  increase = endScore - startScore                             │
  │           = 0.7 - 0.5                                         │
  │           = 0.2                                               │
  │                                                               │
  │  childArousalIncreased = (increase ≥ 0.2)                     │
  │  childArousalIncreased = true ✓                               │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  BOTH CONDITIONS MET → NEGATIVE CO-REGULATION DETECTED!       │
  │                                                               │
  │  Create Event:                                                │
  │  ────────────                                                 │
  │  type: NegativeCoRegulation                                   │
  │  sessionID: <session UUID>                                    │
  │  startTime: 45.0s                                             │
  │  endTime: 46.33s                                              │
  │  duration: 1.33s                                              │
  │  parentEmotionAtStart: Stressed                               │
  │  childArousalAtStart: Yellow                                  │
  │  childArousalAtEnd: Orange                                    │
  │  description: "Your stress may have contributed to escalation"│
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  Return this event (or continue if looking for positive)

╔═══════════════════════════════════════════════════════════════════╗
║                    VISUALIZATION                                   ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Timeline View with Co-Regulation Events:                     │
  │  ───────────────────────────────────────                      │
  │                                                               │
  │  Parent Emotion:                                              │
  │  ───────────────                                              │
  │  Calm ═════════════════════════╗                              │
  │                                ║                              │
  │                    Stressed ═══╬═══════════                   │
  │                                ║                              │
  │  Child Arousal:                ▼                              │
  │  ──────────────                                               │
  │  Yellow ════════════════════ Green  ← Positive Co-Reg         │
  │                                                               │
  │                                                               │
  │                    Yellow ═══════ Orange  ← Negative Co-Reg   │
  │                                                               │
  │  Time: ├────┼────┼────┼────┼────┼────┼────┼────┼────┤        │
  │        0s   10s  20s  30s  40s  50s  60s                      │
  │                   ↑               ↑                           │
  │                   │               │                           │
  │              Positive Event  Negative Event                   │
  │              (20-21s)        (45-46s)                         │
  └──────────────────────────────────────────────────────────────┘

KEY INNOVATIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. BIDIRECTIONAL: Detects both helpful and harmful co-regulation
2. TEMPORAL WINDOWS: 5-sample windows avoid false positives
3. PARENT-CHILD LINKAGE: Direct correlation between states
4. ACTIONABLE FEEDBACK: Specific, constructive guidance
5. PATTERN LEARNING: Identifies what works for each family
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FIGURE 8: ENCRYPTION ARCHITECTURE

### Description
Complete encryption system with AES-256-GCM and Secure Enclave key management.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│              END-TO-END ENCRYPTION ARCHITECTURE                      │
│             (AES-256-GCM with Secure Enclave)                        │
└─────────────────────────────────────────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════════╗
║                MASTER KEY LIFECYCLE                                ║
╚═══════════════════════════════════════════════════════════════════╝

FIRST LAUNCH:
─────────────

  ┌──────────────────────────────────────────────────────────────┐
  │  1. Generate Master Key:                                      │
  │     ────────────────────                                      │
  │     masterKey = SymmetricKey(size: .bits256)                  │
  │     → 256-bit random key (32 bytes)                           │
  │     → Cryptographically secure random number generator        │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  2. Store in iOS Keychain:                                    │
  │     ──────────────────────                                    │
  │     kSecClass: kSecClassGenericPassword                       │
  │     kSecAttrAccount: "com.neuroguide.storage.masterKey"       │
  │     kSecValueData: <256-bit key data>                         │
  │                                                               │
  │     SECURITY ATTRIBUTES:                                      │
  │     ─────────────────────                                     │
  │     • kSecAttrAccessible:                                     │
  │       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly        │
  │       (Available after device unlocked once, never syncs)     │
  │                                                               │
  │     • kSecAttrSynchronizable: false                           │
  │       (NEVER sync to iCloud)                                  │
  │                                                               │
  │     • kSecAttrAccessControl: (Optional)                       │
  │       SecAccessControlCreateWithFlags(                        │
  │         kSecAttrAccessibleWhenUnlockedThisDeviceOnly,         │
  │         .userPresence  ← Requires Face ID/Touch ID            │
  │       )                                                       │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  3. Protected by Secure Enclave:                              │
  │     ────────────────────────────                              │
  │     ┌───────────────────────────────────┐                     │
  │     │      SECURE ENCLAVE               │                     │
  │     │   (Hardware Security Module)      │                     │
  │     │                                   │                     │
  │     │  ┌─────────────────────────────┐  │                     │
  │     │  │ Master Encryption Key       │  │                     │
  │     │  │ 256-bit (32 bytes)          │  │                     │
  │     │  │                             │  │                     │
  │     │  │ Protected by:               │  │                     │
  │     │  │ • Hardware encryption       │  │                     │
  │     │  │ • Device passcode           │  │                     │
  │     │  │ • Biometric binding (opt)   │  │                     │
  │     │  └─────────────────────────────┘  │                     │
  │     └───────────────────────────────────┘                     │
  └──────────────────────────────────────────────────────────────┘


SUBSEQUENT USES:
────────────────

  ┌──────────────────────────────────────────────────────────────┐
  │  App needs to encrypt/decrypt data:                           │
  │  ──────────────────────────────────                           │
  │                                                               │
  │  1. Request master key from Keychain                          │
  │  2. May trigger Face ID/Touch ID prompt (if configured)       │
  │  3. Secure Enclave verifies device passcode/biometric         │
  │  4. Key released to app if authenticated                      │
  │  5. App uses key for encryption/decryption                    │
  │  6. Key cleared from memory after use                         │
  └──────────────────────────────────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════════╗
║             ENCRYPTION OPERATION (AES-256-GCM)                     ║
╚═══════════════════════════════════════════════════════════════════╝

INPUT: Plaintext Data (SessionAnalysisResult JSON)
         │
         ▼

  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 1: Serialize to Data                                    │
  │  ─────────────────────────                                    │
  │  let jsonData = JSONEncoder().encode(sessionResult)           │
  │  → Data object (variable size, e.g., 50 KB)                   │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 2: Load Master Key from Keychain                        │
  │  ──────────────────────────────────────                       │
  │  let masterKey = keychainService.load(                        │
  │    key: "com.neuroguide.storage.masterKey"                    │
  │  )                                                            │
  │  → SymmetricKey (256 bits)                                    │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 3: Generate Random Nonce                                │
  │  ─────────────────────────────                                │
  │  let nonce = AES.GCM.Nonce()                                  │
  │  → 96-bit (12 bytes) random value                             │
  │  → MUST be unique for each encryption                         │
  │  → Uses cryptographically secure RNG                          │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 4: Encrypt with AES-256-GCM                             │
  │  ────────────────────────────────                             │
  │  let sealedBox = AES.GCM.seal(                                │
  │    jsonData,                  ← plaintext                     │
  │    using: masterKey,          ← 256-bit key                   │
  │    nonce: nonce               ← 96-bit nonce                  │
  │  )                                                            │
  │                                                               │
  │  sealedBox contains:                                          │
  │  • Nonce (12 bytes)                                           │
  │  • Ciphertext (same size as plaintext)                        │
  │  • Authentication Tag (16 bytes)                              │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 5: Extract Combined Data                                │
  │  ──────────────────────────────                               │
  │  let encryptedData = sealedBox.combined                       │
  │                                                               │
  │  Format: [Nonce][Ciphertext][Tag]                             │
  │  Size: 12 + plaintextSize + 16 bytes                          │
  │  Example: 12 + 50,000 + 16 = 50,028 bytes                     │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 6: Write to File with Protection                        │
  │  ─────────────────────────────────────                        │
  │  let fileURL = documentsDir                                   │
  │    .appendingPathComponent("SecureStorage")                   │
  │    .appendingPathComponent("session.xxx.enc")                 │
  │                                                               │
  │  try encryptedData.write(to: fileURL)                         │
  │                                                               │
  │  // Set file protection attribute                             │
  │  try FileManager.default.setAttributes([                      │
  │    .protectionKey:                                            │
  │      .completeUntilFirstUserAuthentication                    │
  │  ], ofItemAtPath: fileURL.path)                               │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  Encrypted File on Disk ✓


╔═══════════════════════════════════════════════════════════════════╗
║            DECRYPTION OPERATION (AES-256-GCM)                      ║
╚═══════════════════════════════════════════════════════════════════╝

INPUT: Encrypted File Path
         │
         ▼

  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 1: Read Encrypted Data                                  │
  │  ────────────────────────                                     │
  │  let encryptedData = Data(contentsOf: fileURL)                │
  │  → Combined: [Nonce][Ciphertext][Tag]                         │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 2: Load Master Key from Keychain                        │
  │  ──────────────────────────────────────                       │
  │  let masterKey = keychainService.load(                        │
  │    key: "com.neuroguide.storage.masterKey"                    │
  │  )                                                            │
  │  → May trigger Face ID/Touch ID prompt                        │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 3: Create Sealed Box                                    │
  │  ─────────────────────────                                    │
  │  let sealedBox = AES.GCM.SealedBox(combined: encryptedData)   │
  │  → Parses nonce, ciphertext, tag from combined data           │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 4: Decrypt and Verify                                   │
  │  ──────────────────────────                                   │
  │  let decryptedData = AES.GCM.open(                            │
  │    sealedBox,                                                 │
  │    using: masterKey                                           │
  │  )                                                            │
  │                                                               │
  │  This operation:                                              │
  │  • Decrypts ciphertext using key and nonce                    │
  │  • Verifies authentication tag                                │
  │  • THROWS ERROR if tag verification fails                     │
  │    (prevents tampering/corruption)                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  STEP 5: Deserialize JSON                                     │
  │  ────────────────────────                                     │
  │  let sessionResult = JSONDecoder().decode(                    │
  │    SessionAnalysisResult.self,                                │
  │    from: decryptedData                                        │
  │  )                                                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  Decrypted SessionAnalysisResult ✓


SECURITY PROPERTIES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. CONFIDENTIALITY: Data encrypted, unreadable without key
2. INTEGRITY: Authentication tag ensures no tampering
3. AUTHENTICITY: Only holder of master key can create valid ciphertext
4. NON-MALLEABILITY: Cannot modify ciphertext without detection
5. FORWARD SECRECY: Unique nonce per encryption prevents pattern analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

THREAT MITIGATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Device Theft (Locked): Data encrypted, key in Secure Enclave
✓ Device Theft (Unlocked): Biometric app lock (30s timeout)
✓ Backup Extraction: Master key never backed up
✓ File System Access: All files encrypted
✓ Memory Dump: Key cleared after use
✓ Man-in-the-Middle: No network transmission
✓ Tampering: Authentication tag verification
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Due to token constraints, I'll create a summary document for the remaining figures and provide guidance on how to complete them:

---

## REMAINING FIGURES (9-15) - Summary

I've created comprehensive diagrams for Figures 1-8. The remaining figures to complete are:

**Figure 9: Privacy Verification System**
- Network monitoring during ML operations
- Privacy status verification flow
- Compliance checking process

**Figure 10: User Interface Flow**
- Complete UI navigation diagram
- Screen transitions
- User interaction paths for both modes

**Figure 11: Data Models**
- SessionAnalysisResult structure
- ArousalBandSample and EmotionSample
- BehaviorSpectrum and related models

**Figure 12: Hardware Components**
- iOS device diagram showing all hardware elements
- Dual camera positioning
- Secure Enclave, Neural Engine placement

**Figure 13: Arousal Timeline Visualization**
- Interactive graph design
- Tap-to-detail interaction
- Time axis and arousal bands

**Figure 14: Parent Emotion Analysis**
- Parent emotion classification flow
- Regulation advice generation
- Specific moment identification

**Figure 15: Session Recording Flow**
- Dual-camera H.264 recording
- Battery monitoring
- Auto-stop mechanism

Would you like me to:
1. Complete all remaining figures in a new file?
2. Create simplified summary versions?
3. Focus on specific figures that are most critical for the patent?

These diagrams provide strong patent support by visualizing the novel technical implementations!