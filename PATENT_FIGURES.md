# PATENT FIGURES AND DIAGRAMS
## NeuroGuide - Privacy-First Behavioral Analysis System

**For:** Patent Application Support
**Version:** 1.0
**Created:** [DATE]

---

## TABLE OF CONTENTS

1. [Figure 1: System Architecture Overview](#figure-1-system-architecture-overview)
2. [Figure 2: Dual-Mode Operation Flow](#figure-2-dual-mode-operation-flow)
3. [Figure 3: Real-Time Processing Pipeline](#figure-3-real-time-processing-pipeline)
4. [Figure 4: Record-First Processing Pipeline](#figure-4-record-first-processing-pipeline)
5. [Figure 5: Multimodal Signal Fusion Algorithm](#figure-5-multimodal-signal-fusion-algorithm)
6. [Figure 6: Behavioral Spectrum Generation](#figure-6-behavioral-spectrum-generation)
7. [Figure 7: Co-Regulation Detection](#figure-7-co-regulation-detection)
8. [Figure 8: Encryption Architecture](#figure-8-encryption-architecture)
9. [Figure 9: Privacy Verification System](#figure-9-privacy-verification-system)
10. [Figure 10: User Interface Flow](#figure-10-user-interface-flow)
11. [Figure 11: Data Models](#figure-11-data-models)
12. [Figure 12: Hardware Components](#figure-12-hardware-components)
13. [Figure 13: Arousal Timeline Visualization](#figure-13-arousal-timeline-visualization)
14. [Figure 14: Parent Emotion Analysis](#figure-14-parent-emotion-analysis)
15. [Figure 15: Session Recording Flow](#figure-15-session-recording-flow)

---

## FIGURE 1: SYSTEM ARCHITECTURE OVERVIEW

### Description
High-level system architecture showing all major components and their relationships.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NEUROGUIDE SYSTEM                            │
│                    Privacy-First Behavioral Analysis                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  Live Coach  │  │   Settings   │  │   Profile    │             │
│  │     View     │  │     View     │  │  Management  │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   Results    │  │   History    │  │     Help     │             │
│  │     View     │  │     View     │  │  & Support   │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │            LiveCoachViewModel (Session Management)            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ SessionRecording     │  │  VideoProcessingPipeline          │  │
│  │ Manager              │  │  (Post-Recording Analysis)        │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ DualCameraManager    │  │  SessionHistoryManager            │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                   MACHINE LEARNING SERVICES LAYER                    │
├─────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────────┐│
│  │         ArousalBandClassifier (Multimodal Fusion)              ││
│  │  Combines: Pose + Facial Expression + Vocal Affect → Arousal  ││
│  └────────────────────────────────────────────────────────────────┘│
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ EmotionState         │  │  CoRegulationDetector             │  │
│  │ Classifier           │  │  (Parent-Child Synchronization)   │  │
│  │ (Parent Emotions)    │  │                                   │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │    Pose      │  │   Facial     │  │    Vocal Affect      │  │
│  │  Detection   │  │  Expression  │  │     Service          │  │
│  │   Service    │  │   Service    │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    SECURITY & STORAGE LAYER                          │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ EncryptionService    │  │  KeychainService                  │  │
│  │ AES-256-GCM          │  │  (Secure Enclave Key Management)  │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ SecureStorage        │  │  BiometricAuthService             │  │
│  │ Service              │  │  (Face ID / Touch ID)             │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ PrivacyManager       │  │  AppLockManager                   │  │
│  │ (Network Monitoring) │  │  (Biometric App Lock)             │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    iOS SYSTEM FRAMEWORKS                             │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │ Core ML  │  │  Vision  │  │ AVFoundation │  │  CryptoKit  │  │
│  │ (Neural  │  │ (Image   │  │ (Camera &    │  │ (AES-256-   │  │
│  │ Networks)│  │ Analysis)│  │  Audio)      │  │  GCM)       │  │
│  └──────────┘  └──────────┘  └──────────────┘  └─────────────┘  │
│  ┌──────────────┐  ┌──────────┐                                   │
│  │    Local     │  │ Security │                                   │
│  │ Authentication│ │ (Keychain│                                   │
│  │ (Biometrics) │  │  API)    │                                   │
│  └──────────────┘  └──────────┘                                   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         HARDWARE LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐│
│  │   Neural     │  │    Secure    │  │   Dual Camera System     ││
│  │   Engine     │  │   Enclave    │  │  (Front + Rear 1080p)    ││
│  │ (ML Accel.)  │  │ (Crypto)     │  │                          ││
│  └──────────────┘  └──────────────┘  └──────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘

KEY PRINCIPLES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. ALL PROCESSING ON-DEVICE (No Network Connectivity Required)
2. END-TO-END ENCRYPTION (AES-256-GCM with Secure Enclave Keys)
3. PRIVACY VERIFICATION (Active Network Monitoring During ML Operations)
4. BIOMETRIC PROTECTION (Face ID / Touch ID App Lock)
5. TEMPORARY VIDEO STORAGE (Deleted After Processing)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Component Description

**Presentation Layer:**
- SwiftUI-based responsive user interfaces
- Accessibility support (VoiceOver, Dynamic Type, High Contrast)
- Real-time data binding via Combine framework

**Business Logic Layer:**
- LiveCoachViewModel: Manages session lifecycle, state, camera coordination
- SessionRecordingManager: Dual-camera H.264 video recording
- VideoProcessingPipeline: Post-recording ML analysis
- DualCameraManager: AVCaptureMultiCamSession coordination

**ML Services Layer:**
- All inference occurs on-device using Core ML
- Multimodal fusion (pose + facial + vocal)
- Temporal smoothing for stability
- Parent-child co-regulation detection

**Security & Storage Layer:**
- Military-grade AES-256-GCM encryption
- Secure Enclave key storage
- Biometric authentication
- Privacy verification and network monitoring

---

## FIGURE 2: DUAL-MODE OPERATION FLOW

### Description
Comparison of Real-Time Mode vs Record-First Mode operation.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DUAL-MODE ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════════╗
║                         REAL-TIME MODE                             ║
║              (Instant Analysis & Coaching)                         ║
╚═══════════════════════════════════════════════════════════════════╝

  User Starts Session
         │
         ▼
  ┌─────────────────┐
  │  Setup Dual     │
  │  Camera System  │──────────► Front Camera (Parent)
  │  (1080p @ 30fps)│           Rear Camera (Child)
  └────────┬────────┘
           │
           ▼
  ┌─────────────────────────────────────────────┐
  │  For Each Frame (30 FPS):                   │
  │  ────────────────────────────                │
  │  1. Capture child frame                     │
  │  2. Capture parent frame                    │
  │  3. Run ML Analysis:                        │
  │     • Pose Detection                        │
  │     • Facial Expression                     │
  │     • Vocal Affect (if audio)               │
  │  4. Classify Arousal Band                   │
  │  5. Detect Parent Emotion                   │
  │  6. Check for Co-Regulation                 │
  │  7. Generate Coaching Suggestions           │
  │  8. Update UI Instantly                     │
  └────────┬────────────────────────────────────┘
           │
           ▼
  ┌─────────────────┐
  │  Display Live   │
  │  Arousal Band   │
  │  Confidence     │
  │  Suggestions    │
  └────────┬────────┘
           │
           ▼
  User Ends Session
         │
         ▼
  ┌─────────────────┐
  │  Save Session   │
  │  Metadata Only  │
  │  (No Video)     │
  └─────────────────┘


╔═══════════════════════════════════════════════════════════════════╗
║                      RECORD-FIRST MODE                             ║
║         (Comprehensive Post-Recording Analysis)                    ║
╚═══════════════════════════════════════════════════════════════════╝

  User Starts Session
         │
         ▼
  ┌─────────────────┐
  │  Setup Dual     │
  │  Camera System  │──────────► Front Camera (Parent)
  │  (1080p @ 30fps)│           Rear Camera (Child)
  └────────┬────────┘
           │
           ▼
  ╔═══════════════════════════════════════════════════╗
  ║         STAGE 1: RECORDING (0-60 seconds)         ║
  ╚═══════════════════════════════════════════════════╝
         │
  ┌─────────────────────────────────────────────┐
  │  Start H.264 Recording:                     │
  │  ──────────────────────                     │
  │  • Child video → temp file                  │
  │  • Parent video → temp file                 │
  │  • Display countdown timer                  │
  │  • Show recording indicator (red dot)       │
  │  • Monitor battery level                    │
  │  • NO ML PROCESSING (preview only)          │
  └────────┬────────────────────────────────────┘
           │
           ▼
  Recording Completes (60s or user stops)
         │
         ▼
  ╔═══════════════════════════════════════════════════╗
  ║      STAGE 2: PROCESSING (Variable Duration)      ║
  ╚═══════════════════════════════════════════════════╝
         │
  ┌─────────────────────────────────────────────┐
  │  Video Processing Pipeline:                 │
  │  ─────────────────────────                  │
  │  1. Extract frames @ 3 FPS                  │
  │  2. For each child frame:                   │
  │     • Convert CVPixelBuffer → CGImage       │
  │     • Run Pose Detection                    │
  │     • Run Facial Expression                 │
  │     • Classify Arousal Band                 │
  │     • Store ArousalBandSample + timestamp   │
  │  3. For each parent frame:                  │
  │     • Run Facial Expression                 │
  │     • Classify Parent Emotion               │
  │     • Store EmotionSample + timestamp       │
  │  4. Generate BehaviorSpectrum:              │
  │     • Calculate % time in each band         │
  │     • Blend child profile color             │
  │  5. Detect Co-Regulation Events             │
  │  6. Generate Coaching Suggestions           │
  │  7. Create ParentRegulationAdvice           │
  └────────┬────────────────────────────────────┘
           │
           ▼
  ┌─────────────────┐
  │  Delete Temp    │
  │  Video Files    │
  └────────┬────────┘
           │
           ▼
  ╔═══════════════════════════════════════════════════╗
  ║          STAGE 3: RESULTS DISPLAY                 ║
  ╚═══════════════════════════════════════════════════╝
         │
  ┌─────────────────────────────────────────────┐
  │  Interactive Results View:                  │
  │  ────────────────────────                   │
  │  • Behavioral Spectrum (Color Bar)          │
  │  • Arousal Timeline Graph (Interactive)     │
  │  • Parent Emotion Summary                   │
  │  • Co-Regulation Events (if detected)       │
  │  • Coaching Suggestions (Prioritized)       │
  │  • Save/Discard Session Options             │
  └────────┬────────────────────────────────────┘
           │
           ▼
  User Saves or Discards
         │
         ▼
  ┌─────────────────┐
  │  Store Encrypted│
  │  Analysis       │
  │  Results Only   │
  │  (4-week limit) │
  └─────────────────┘


╔═══════════════════════════════════════════════════════════════════╗
║                      MODE SELECTION                                ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌─────────────────────────────────────────────────────────────┐
  │  Settings → Live Coach Mode                                  │
  │  ─────────────────────────                                   │
  │                                                              │
  │  ◉ Real-Time Mode                                           │
  │    Get instant coaching suggestions as you interact         │
  │    Requires: Continuous camera and processing               │
  │                                                              │
  │  ○ Record-First Mode (Recommended)                          │
  │    Record session first, then receive detailed analysis     │
  │    Benefits: Better privacy, comprehensive insights         │
  │                                                              │
  └─────────────────────────────────────────────────────────────┘

KEY DIFFERENCES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────┬─────────────────┬───────────────────────────┐
│   Feature       │  Real-Time      │   Record-First            │
├─────────────────┼─────────────────┼───────────────────────────┤
│ Processing      │ Live            │ After Session             │
│ Battery Usage   │ Higher          │ Lower                     │
│ Privacy         │ Good            │ Excellent                 │
│ Analysis Depth  │ Basic           │ Comprehensive             │
│ Video Replay    │ No              │ No (deleted after)        │
│ Session History │ Limited         │ Full (4 weeks)            │
│ Spectrum View   │ No              │ Yes                       │
│ Timeline Graph  │ No              │ Yes                       │
│ Parent Advice   │ Basic           │ Detailed                  │
└─────────────────┴─────────────────┴───────────────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FIGURE 3: REAL-TIME PROCESSING PIPELINE

### Description
Detailed flow of real-time multimodal analysis and coaching suggestion generation.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                   REAL-TIME PROCESSING PIPELINE                      │
│                        (30 FPS Frame Rate)                           │
└─────────────────────────────────────────────────────────────────────┘

Frame N arrives (33ms interval)
         │
         ├────────────► Child Frame (CGImage)
         │
         └────────────► Parent Frame (CGImage)
         │
         ▼

┌────────────────────────────────────────────────────────────────────┐
│  CHILD FRAME PROCESSING (Parallel Execution)                       │
└────────────────────────────────────────────────────────────────────┘
         │
         ├──────────────────────┬──────────────────────┬─────────────
         │                      │                      │
         ▼                      ▼                      ▼
  ┌─────────────┐      ┌──────────────┐      ┌──────────────┐
  │    POSE     │      │   FACIAL     │      │    VOCAL     │
  │ DETECTION   │      │  EXPRESSION  │      │    AFFECT    │
  │             │      │              │      │              │
  │ Vision      │      │ Vision       │      │ Audio        │
  │ Framework   │      │ Framework    │      │ Analysis     │
  └──────┬──────┘      └──────┬───────┘      └──────┬───────┘
         │                    │                      │
         │ PoseFeatures       │ FacialFeatures       │ VocalFeatures
         │ • Landmarks        │ • Expression         │ • Pitch
         │ • Confidence       │ • Intensity          │ • Volume
         │ • Movement         │ • Confidence         │ • Speech Rate
         │                    │                      │
         └────────────────────┴──────────────────────┘
                              │
                              ▼
         ┌──────────────────────────────────────────┐
         │   MULTIMODAL SIGNAL FUSION                │
         │   ────────────────────────                │
         │                                           │
         │   1. Calculate Arousal Contributions:     │
         │      • Pose: Movement intensity           │
         │      • Facial: Expression intensity       │
         │      • Vocal: Pitch variability           │
         │                                           │
         │   2. Adaptive Weighting:                  │
         │      weight_i = confidence_i / Σconfidence│
         │                                           │
         │   3. Fused Arousal Score:                 │
         │      score = Σ(contribution_i * weight_i) │
         │                                           │
         │   4. Map to Arousal Band:                 │
         │      < 0.15 → Shutdown                    │
         │      < 0.40 → Green                       │
         │      < 0.60 → Yellow                      │
         │      < 0.80 → Orange                      │
         │      ≥ 0.80 → Red                         │
         │                                           │
         │   5. Temporal Smoothing:                  │
         │      Use 5-sample rolling window          │
         │      Apply majority voting                │
         └────────────────┬──────────────────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ ArousalBand     │
                 │ Classification  │
                 │                 │
                 │ • Band: Yellow  │
                 │ • Confidence: 0.73 │
                 │ • Timestamp     │
                 └────────┬────────┘
                          │
                          ▼

┌────────────────────────────────────────────────────────────────────┐
│  PARENT FRAME PROCESSING                                           │
└────────────────────────────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────┐
  │   FACIAL     │
  │  EXPRESSION  │
  │  ANALYSIS    │
  │              │
  │ Classifies:  │
  │ • Calm       │
  │ • Regulated  │
  │ • Stressed   │
  │ • Anxious    │
  │ • Frustrated │
  │ • Overwhelmed│
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │ ParentEmotion│
  │ Classification│
  │              │
  │ • Emotion: Stressed│
  │ • Intensity: 0.65  │
  │ • Timestamp  │
  └──────┬───────┘
         │
         ▼

┌────────────────────────────────────────────────────────────────────┐
│  CO-REGULATION DETECTION                                           │
└────────────────────────────────────────────────────────────────────┘
         │
         ▼
  ┌────────────────────────────────────┐
  │  Analyze Last 5 Samples:           │
  │  ──────────────────────            │
  │                                    │
  │  IF parent_calm AND                │
  │     child_arousal_decreased        │
  │  THEN:                             │
  │     ✓ Positive Co-Regulation       │
  │     "Your calm helped regulate"    │
  │                                    │
  │  IF parent_stressed AND            │
  │     child_arousal_increased        │
  │  THEN:                             │
  │     ✗ Negative Co-Regulation       │
  │     "Your stress may amplify"      │
  └────────────────┬───────────────────┘
                   │
                   ▼

┌────────────────────────────────────────────────────────────────────┐
│  COACHING SUGGESTION GENERATION                                    │
└────────────────────────────────────────────────────────────────────┘
         │
         ▼
  ┌────────────────────────────────────┐
  │  Context Analysis:                 │
  │  ────────────────                  │
  │  • Current arousal: Yellow         │
  │  • Parent state: Stressed          │
  │  • Co-regulation: None detected    │
  │  • Child profile: Age 5, Autism    │
  └────────────────┬───────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────┐
  │  Query Content Library:            │
  │  ─────────────────────            │
  │  • Filter by arousal band (Yellow) │
  │  • Filter by age (5)               │
  │  • Filter by profile               │
  │  • Rank by relevance               │
  └────────────────┬───────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────────┐
  │  Top 3 Coaching Suggestions:                       │
  │  ────────────────────────────                      │
  │                                                    │
  │  1. "Early warning signs detected"                │
  │     Priority: Medium                              │
  │     Category: Preventative Strategy               │
  │                                                    │
  │  2. "Consider a calming break or sensory input"   │
  │     Priority: Medium                              │
  │     Category: De-escalation                       │
  │                                                    │
  │  3. "Try deep breathing together"                 │
  │     Priority: High                                │
  │     Category: Co-Regulation                       │
  │     (Due to parent stress detected)               │
  └────────────────┬───────────────────────────────────┘
                   │
                   ▼

┌────────────────────────────────────────────────────────────────────┐
│  UI UPDATE (Main Thread)                                           │
└────────────────────────────────────────────────────────────────────┘
         │
         ▼
  ┌────────────────────────────────────┐
  │  Update Published Properties:      │
  │  ──────────────────────────        │
  │  @Published currentArousalBand     │
  │  @Published currentConfidence      │
  │  @Published suggestions            │
  │  @Published currentParentState     │
  └────────────────┬───────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────┐
  │  SwiftUI View Refresh:             │
  │  ────────────────────              │
  │  • Arousal Band Card               │
  │  • Confidence Indicator            │
  │  • Coaching Suggestions List       │
  │  • Camera Preview                  │
  └────────────────────────────────────┘
         │
         ▼
  Wait for next frame (33ms) → Repeat


PERFORMANCE METRICS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Frame Rate: 30 FPS (every 33ms)
• Processing Latency: < 33ms (maintains real-time)
• ML Inference Time: ~15-20ms per frame (Neural Engine accelerated)
• UI Update Delay: < 5ms
• Total End-to-End Latency: < 100ms (imperceptible to user)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MEMORY MANAGEMENT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Frame Skipping: Process every 10th frame (~3 FPS actual processing)
• Autoreleasepool: Used for CVPixelBuffer conversion
• History Pruning: Keep only last 5 samples
• Memory Warnings: Clear ML caches on warning
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FIGURE 4: RECORD-FIRST PROCESSING PIPELINE

### Description
Detailed flow of post-recording video analysis with comprehensive insights generation.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│              RECORD-FIRST PROCESSING PIPELINE                        │
│           (Post-Recording Comprehensive Analysis)                    │
└─────────────────────────────────────────────────────────────────────┘

User Completes Recording (60 seconds)
         │
         ▼
  ┌──────────────────────────────────┐
  │  Input:                          │
  │  • Child video URL               │
  │  • Parent video URL              │
  │  • Child ID                      │
  │  • Child name                    │
  │  • Profile color                 │
  └────────────┬─────────────────────┘
               │
               ▼

╔═══════════════════════════════════════════════════════════════════╗
║                   STAGE 1: FRAME EXTRACTION                        ║
╚═══════════════════════════════════════════════════════════════════╝
               │
         ┌─────┴─────┐
         │           │
         ▼           ▼
  ┌───────────┐   ┌───────────┐
  │  Child    │   │  Parent   │
  │  Video    │   │  Video    │
  │  (H.264)  │   │  (H.264)  │
  └─────┬─────┘   └─────┬─────┘
        │               │
        │               │
        ▼               ▼
  ┌───────────────────────────────────┐
  │  AVAssetReader                    │
  │  Extract frames @ 3 FPS           │
  │  ────────────────────             │
  │  60 seconds @ 3 FPS = 180 frames  │
  │  per video stream                 │
  └───────┬────────────────┬──────────┘
          │                │
          ▼                ▼
  Child Frames      Parent Frames
  (180 total)       (180 total)


╔═══════════════════════════════════════════════════════════════════╗
║              STAGE 2: CHILD BEHAVIOR ANALYSIS                      ║
╚═══════════════════════════════════════════════════════════════════╝
          │
          ▼
  For each of 180 child frames:
  ────────────────────────────
          │
          ▼
  ┌────────────────────────────────────┐
  │  Frame N Processing:               │
  │  ──────────────────                │
  │  1. CVPixelBuffer → CGImage        │
  │  2. Run Pose Detection             │
  │  3. Run Facial Expression          │
  │  4. Calculate arousal contribution │
  │  5. Fuse signals → ArousalBand     │
  │  6. Store sample with timestamp    │
  └────────────────┬───────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  ArousalBandSample Collection:                 │
  │  ────────────────────────────                  │
  │  [                                             │
  │    { timestamp: 0.0,  band: Green,    conf: 0.82 }, │
  │    { timestamp: 0.33, band: Green,    conf: 0.79 }, │
  │    { timestamp: 0.66, band: Green,    conf: 0.81 }, │
  │    ...                                         │
  │    { timestamp: 59.0, band: Yellow,   conf: 0.71 }, │
  │    { timestamp: 59.33, band: Yellow,  conf: 0.68 }, │
  │    { timestamp: 59.66, band: Orange,  conf: 0.73 }  │
  │  ]                                             │
  │  Total: 180 samples                            │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║             STAGE 3: PARENT EMOTION ANALYSIS                       ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  For each of 180 parent frames:
  ────────────────────────────
                   │
                   ▼
  ┌────────────────────────────────────┐
  │  Frame N Processing:               │
  │  ──────────────────                │
  │  1. CVPixelBuffer → CGImage        │
  │  2. Run Facial Expression          │
  │  3. Map to Parent Emotion          │
  │  4. Store sample with timestamp    │
  └────────────────┬───────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  EmotionSample Collection:                     │
  │  ────────────────────────                      │
  │  [                                             │
  │    { timestamp: 0.0,  emotion: Calm,      int: 0.55 }, │
  │    { timestamp: 0.33, emotion: Calm,      int: 0.61 }, │
  │    { timestamp: 0.66, emotion: Calm,      int: 0.58 }, │
  │    ...                                         │
  │    { timestamp: 40.0, emotion: Stressed,  int: 0.72 }, │
  │    { timestamp: 45.0, emotion: Anxious,   int: 0.78 }, │
  │    { timestamp: 59.66, emotion: Anxious,  int: 0.81 }  │
  │  ]                                             │
  │  Total: 180 samples                            │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║           STAGE 4: BEHAVIORAL SPECTRUM GENERATION                  ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Calculate Band Distribution:                  │
  │  ───────────────────────────                   │
  │                                                │
  │  Shutdown: 5 samples  → 2.8%                   │
  │  Green:    110 samples → 61.1%                 │
  │  Yellow:   45 samples  → 25.0%                 │
  │  Orange:   15 samples  → 8.3%                  │
  │  Red:      5 samples   → 2.8%                  │
  │                                                │
  │  Dominant Band: Green                          │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Apply Child Profile Color Blending:           │
  │  ──────────────────────────────────           │
  │                                                │
  │  Profile Color: #4A90E2 (Blue)                 │
  │  Blend Ratio: 30% profile + 70% band color     │
  │                                                │
  │  Blended Colors:                               │
  │  • Shutdown → Blue + Blue (darker)             │
  │  • Green → Blue + Green (teal)                 │
  │  • Yellow → Blue + Yellow (blue-yellow)        │
  │  • Orange → Blue + Orange (muted orange)       │
  │  • Red → Blue + Red (purple-red)               │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  BehaviorSpectrum:                             │
  │  ────────────────                              │
  │  ┌────────────────────────────────────────┐   │
  │  │ ████████Green 61%██████                │   │
  │  │ ██Yellow 25%██  Orange 8%  Other 5%    │   │
  │  └────────────────────────────────────────┘   │
  │  (All in personalized blue tint)               │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║            STAGE 5: CO-REGULATION DETECTION                        ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Align Timelines:                              │
  │  ───────────────                               │
  │  Merge arousal + emotion samples by timestamp  │
  │  Interpolate if necessary                      │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Scan for Co-Regulation Patterns:              │
  │  ───────────────────────────────               │
  │                                                │
  │  Looking for 5-sample windows where:           │
  │  • Parent maintained calm/regulated            │
  │  • Child arousal decreased ≥ 0.2               │
  │                                                │
  │  OR                                            │
  │                                                │
  │  • Parent stressed/anxious/overwhelmed         │
  │  • Child arousal increased ≥ 0.2               │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Result:                                       │
  │  ──────                                        │
  │  ✓ Positive Co-Regulation Detected             │
  │                                                │
  │  Event Details:                                │
  │  • Start Time: 22.5s                           │
  │  • End Time: 24.0s                             │
  │  • Parent: Calm                                │
  │  • Child: Yellow → Green                       │
  │  • Description: "Your calm presence helped     │
  │    regulate your child"                        │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║         STAGE 6: PARENT REGULATION ADVICE GENERATION               ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Analyze Parent Emotion Distribution:          │
  │  ───────────────────────────────────           │
  │                                                │
  │  Calm:        80 samples (44%)                 │
  │  Regulated:   30 samples (17%)                 │
  │  Stressed:    50 samples (28%)  ← Dominant     │
  │  Anxious:     15 samples (8%)                  │
  │  Frustrated:  5 samples  (3%)                  │
  │  Overwhelmed: 0 samples  (0%)                  │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  ParentRegulationAdvice:                       │
  │  ──────────────────────                        │
  │                                                │
  │  Dominant Emotion: Stressed (28%)              │
  │                                                │
  │  Regulation Strategies:                        │
  │  • "Take deep breaths - your regulation        │
  │    supports your child's regulation"           │
  │  • "Consider a brief break or tag-team         │
  │    with your partner"                          │
  │  • "Remember: This is hard, and you're         │
  │    doing your best"                            │
  │                                                │
  │  Specific Moments:                             │
  │  • 40.0s: Stressed detected - "Consider        │
  │    pausing for self-regulation"                │
  │  • 45.0s: Anxious detected - "Your child       │
  │    may sense your anxiety"                     │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║           STAGE 7: COACHING SUGGESTIONS GENERATION                 ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Context Synthesis:                            │
  │  ─────────────────                             │
  │  • Dominant child band: Green (61%)            │
  │  • Secondary band: Yellow (25%)                │
  │  • Dominant parent emotion: Stressed (28%)     │
  │  • Co-regulation: Positive event detected      │
  │  • Child profile: Age 5, Autism, Sensory SPD   │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Generate Top 5 Coaching Suggestions:          │
  │  ───────────────────────────────────           │
  │                                                │
  │  1. ✓ "Great session! Your child was mostly    │
  │     regulated (61% green zone)"                │
  │     Category: Positive Reinforcement           │
  │     Priority: Medium                           │
  │                                                │
  │  2. ⚠ "Watch for early warning signs - 25%     │
  │     time in yellow zone"                       │
  │     Category: Preventative Strategy            │
  │     Priority: Medium                           │
  │                                                │
  │  3. 🧘 "Your calm at 22.5s helped regulate     │
  │     your child - keep using this strategy"     │
  │     Category: Co-Regulation Success            │
  │     Priority: High                             │
  │                                                │
  │  4. 💙 "You showed signs of stress. Remember:  │
  │     your regulation supports theirs"           │
  │     Category: Parent Self-Care                 │
  │     Priority: High                             │
  │                                                │
  │  5. 🎯 "For yellow moments: Try calming        │
  │     activities or sensory input"               │
  │     Category: De-Escalation                    │
  │     Priority: Medium                           │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║                STAGE 8: RESULT ASSEMBLY                            ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  SessionAnalysisResult:                        │
  │  ─────────────────────                         │
  │                                                │
  │  ID: UUID                                      │
  │  Child: "Emma" (ID: xxx)                       │
  │  Recorded: 2025-10-30 14:35:00                 │
  │  Duration: 60.0 seconds                        │
  │                                                │
  │  ├─ BehaviorSpectrum                           │
  │  │  • Shutdown: 2.8%                           │
  │  │  • Green: 61.1%                             │
  │  │  • Yellow: 25.0%                            │
  │  │  • Orange: 8.3%                             │
  │  │  • Red: 2.8%                                │
  │  │  • Dominant: Green                          │
  │  │                                             │
  │  ├─ ArousalTimeline (180 samples)              │
  │  │                                             │
  │  ├─ ParentEmotionTimeline (180 samples)        │
  │  │                                             │
  │  ├─ CoachingSuggestions (5 items)              │
  │  │                                             │
  │  ├─ ParentAdvice                               │
  │  │  • Dominant: Stressed (28%)                 │
  │  │  • Strategies: [3 items]                    │
  │  │  • Specific Moments: [2 items]              │
  │  │                                             │
  │  └─ Processing Duration: 45.2 seconds          │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║                 STAGE 9: VIDEO CLEANUP                             ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Delete Temporary Video Files:                 │
  │  ────────────────────────────                  │
  │  ✓ Child video deleted                         │
  │  ✓ Parent video deleted                        │
  │                                                │
  │  Privacy Guarantee:                            │
  │  Raw video never stored beyond processing      │
  │  Only encrypted analysis results remain        │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼

╔═══════════════════════════════════════════════════════════════════╗
║              STAGE 10: ENCRYPTED STORAGE                           ║
╚═══════════════════════════════════════════════════════════════════╝
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Encrypt SessionAnalysisResult:                │
  │  ─────────────────────────────                 │
  │  1. Serialize to JSON                          │
  │  2. Encrypt with AES-256-GCM                   │
  │  3. Store in SecureStorage/                    │
  │  4. Add to SessionHistoryManager               │
  │  5. Enforce 4-week retention limit             │
  └────────────────┬───────────────────────────────┘
                   │
                   ▼
  ┌────────────────────────────────────────────────┐
  │  Display Results to User                       │
  │  (Interactive Visualization)                   │
  └────────────────────────────────────────────────┘


PERFORMANCE METRICS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Total Processing Time: ~45-60 seconds for 60-second video
• Frame Extraction: ~5 seconds
• Child Analysis: ~20-25 seconds (180 frames @ 3 FPS)
• Parent Analysis: ~15-20 seconds (180 frames @ 3 FPS)
• Insights Generation: ~5 seconds
• Cleanup & Storage: < 1 second
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRIVACY GUARANTEES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ All processing on-device (100%)
✓ No network connectivity required or used
✓ Temporary videos deleted immediately after processing
✓ Only encrypted analysis results stored (no raw video)
✓ 4-week automatic data retention limit
✓ User can manually delete sessions anytime
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FIGURE 5: MULTIMODAL SIGNAL FUSION ALGORITHM

### Description
Detailed flowchart of the novel multimodal arousal classification algorithm.

### ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│          MULTIMODAL AROUSAL BAND CLASSIFICATION ALGORITHM            │
│        (Adaptive Fusion with Signal Quality Weighting)              │
└─────────────────────────────────────────────────────────────────────┘

INPUT: VideoFrame (CGImage), AudioBuffer (AVAudioPCMBuffer)
         │
         ▼

╔═══════════════════════════════════════════════════════════════════╗
║              STEP 1: PARALLEL FEATURE EXTRACTION                   ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  async parallel:                                              │
  │     poseFeatures = extractPoseFeatures(videoFrame)           │
  │     facialFeatures = extractFacialFeatures(videoFrame)       │
  │     vocalFeatures = extractVocalFeatures(audioBuffer)        │
  └──────────────────┬───────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┬─────────────────┐
         │                       │                 │
         ▼                       ▼                 ▼

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  PoseFeatures   │    │ FacialFeatures  │    │ VocalFeatures   │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│• landmarks: []  │    │• expression:    │    │• pitch: []      │
│• confidence:0.85│    │  intensity: 0.72│    │• volume: 0.65   │
│• movement:      │    │• mouthOpen: 0.4 │    │• speechRate:    │
│  intensity: 0.6 │    │• eyeOpen: 0.8   │    │  1.2 words/sec  │
│• gestureFreq:   │    │• browPos: 0.3   │    │• snr: 0.7       │
│  0.5 Hz         │    │• confidence:0.78│    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                     │
         └───────────┬───────────┴─────────────────────┘
                     │
                     ▼

╔═══════════════════════════════════════════════════════════════════╗
║        STEP 2: CALCULATE AROUSAL CONTRIBUTIONS (0.0-1.0)           ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  POSE CONTRIBUTION:                                           │
  │  ─────────────────                                            │
  │  movementScore = movementIntensity = 0.6                      │
  │  gestureScore = gestureFrequency / maxFreq = 0.5 / 2.0 = 0.25 │
  │  postureScore = 1.0 - postureStability = 1.0 - 0.7 = 0.3      │
  │                                                               │
  │  poseContribution = weightedAvg([                             │
  │    (movementScore, 0.4),    → 0.6 * 0.4 = 0.24                │
  │    (gestureScore, 0.4),     → 0.25 * 0.4 = 0.10               │
  │    (postureScore, 0.2)      → 0.3 * 0.2 = 0.06                │
  │  ]) = 0.24 + 0.10 + 0.06 = 0.40                               │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  FACIAL CONTRIBUTION:                                         │
  │  ───────────────────                                          │
  │  expressionScore = expressionIntensity = 0.72                 │
  │  eyeScore = eyeOpenness = 0.8                                 │
  │  jawScore = jawTension = abs(browPosition) = 0.3              │
  │                                                               │
  │  facialContribution = weightedAvg([                           │
  │    (expressionScore, 0.5),  → 0.72 * 0.5 = 0.36               │
  │    (eyeScore, 0.3),         → 0.8 * 0.3 = 0.24                │
  │    (jawScore, 0.2)          → 0.3 * 0.2 = 0.06                │
  │  ]) = 0.36 + 0.24 + 0.06 = 0.66                               │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  VOCAL CONTRIBUTION:                                          │
  │  ──────────────────                                           │
  │  pitchScore = pitchVariability / maxVariability = 0.45        │
  │  volumeScore = volume = 0.65                                  │
  │  rateScore = speechRate / normalRate = 1.2 / 1.0 = 1.0 (cap) │
  │                                                               │
  │  vocalContribution = weightedAvg([                            │
  │    (pitchScore, 0.4),       → 0.45 * 0.4 = 0.18               │
  │    (volumeScore, 0.4),      → 0.65 * 0.4 = 0.26               │
  │    (rateScore, 0.2)         → 1.0 * 0.2 = 0.20                │
  │  ]) = 0.18 + 0.26 + 0.20 = 0.64                               │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║           STEP 3: ADAPTIVE WEIGHT CALCULATION                      ║
║             (Based on Signal Quality)                              ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Extract Quality Metrics:                                     │
  │  ───────────────────────                                      │
  │  poseWeight = poseFeatures.confidence = 0.85                  │
  │  facialWeight = facialFeatures.confidence = 0.78              │
  │  vocalWeight = vocalFeatures.snr = 0.70  (signal-to-noise)    │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Normalize Weights:                                           │
  │  ─────────────────                                            │
  │  totalWeight = 0.85 + 0.78 + 0.70 = 2.33                      │
  │                                                               │
  │  normalizedPoseWeight = 0.85 / 2.33 = 0.365 (36.5%)           │
  │  normalizedFacialWeight = 0.78 / 2.33 = 0.335 (33.5%)         │
  │  normalizedVocalWeight = 0.70 / 2.33 = 0.300 (30.0%)          │
  │                                                               │
  │  Sum check: 0.365 + 0.335 + 0.300 = 1.000 ✓                   │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║              STEP 4: MULTIMODAL SIGNAL FUSION                      ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Weighted Fusion:                                             │
  │  ───────────────                                              │
  │  fusedArousalScore = (                                        │
  │    poseContribution * normalizedPoseWeight +                  │
  │    facialContribution * normalizedFacialWeight +              │
  │    vocalContribution * normalizedVocalWeight                  │
  │  )                                                            │
  │                                                               │
  │  = (0.40 * 0.365) + (0.66 * 0.335) + (0.64 * 0.300)           │
  │  = 0.146 + 0.221 + 0.192                                      │
  │  = 0.559                                                      │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║            STEP 5: MAP SCORE TO AROUSAL BAND                       ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Arousal Band Thresholds:                                     │
  │  ────────────────────────                                     │
  │                                                               │
  │  if fusedScore < 0.15:  → Shutdown                            │
  │  if fusedScore < 0.40:  → Green                               │
  │  if fusedScore < 0.60:  → Yellow      ◄─── 0.559 maps here   │
  │  if fusedScore < 0.80:  → Orange                              │
  │  if fusedScore ≥ 0.80:  → Red                                 │
  │                                                               │
  │  arousalBand = Yellow                                         │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║          STEP 6: CALCULATE CLASSIFICATION CONFIDENCE               ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Signal Agreement Calculation:                                │
  │  ────────────────────────────                                 │
  │  contributions = [0.40, 0.66, 0.64]                           │
  │  mean = (0.40 + 0.66 + 0.64) / 3 = 0.567                      │
  │                                                               │
  │  variance = (                                                 │
  │    (0.40 - 0.567)² +                                          │
  │    (0.66 - 0.567)² +                                          │
  │    (0.64 - 0.567)²                                            │
  │  ) / 3                                                        │
  │  = (0.028 + 0.009 + 0.005) / 3                                │
  │  = 0.014                                                      │
  │                                                               │
  │  stdDev = sqrt(0.014) = 0.118                                 │
  │                                                               │
  │  agreement = max(0.0, 1.0 - (stdDev * 2.0))                   │
  │            = max(0.0, 1.0 - (0.118 * 2.0))                    │
  │            = max(0.0, 0.764)                                  │
  │            = 0.764                                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Final Confidence:                                            │
  │  ────────────────                                             │
  │  confidence = agreement * min(weights)                        │
  │             = 0.764 * min(0.85, 0.78, 0.70)                   │
  │             = 0.764 * 0.70                                    │
  │             = 0.535                                           │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║              STEP 7: TEMPORAL SMOOTHING                            ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  Arousal History (last 5 readings):                           │
  │  ──────────────────────────────────                           │
  │  [                                                            │
  │    (Green,  0.620),   ← t-4                                   │
  │    (Green,  0.580),   ← t-3                                   │
  │    (Green,  0.610),   ← t-2                                   │
  │    (Yellow, 0.550),   ← t-1                                   │
  │    (Yellow, 0.535)    ← t (current)                           │
  │  ]                                                            │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Majority Voting:                                             │
  │  ───────────────                                              │
  │  bandCounts = {                                               │
  │    Green:  3 occurrences                                      │
  │    Yellow: 2 occurrences                                      │
  │  }                                                            │
  │                                                               │
  │  smoothedBand = mostFrequent = Green                          │
  │  (Requires majority to change band)                           │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Average Confidence:                                          │
  │  ──────────────────                                           │
  │  smoothedConfidence = (0.620 + 0.580 + 0.610 + 0.550 + 0.535) / 5│
  │                     = 2.895 / 5                               │
  │                     = 0.579                                   │
  └────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼

╔═══════════════════════════════════════════════════════════════════╗
║                     FINAL OUTPUT                                   ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │  ArousalBandClassification:                                   │
  │  ─────────────────────────                                    │
  │                                                               │
  │  arousalBand: Green  (smoothed)                               │
  │  confidence: 0.579   (averaged)                               │
  │  rawBand: Yellow     (current frame)                          │
  │  rawConfidence: 0.535                                         │
  │  timestamp: <current time>                                    │
  │                                                               │
  │  contributions:                                               │
  │    pose: 0.40    (weight: 36.5%)                              │
  │    facial: 0.66  (weight: 33.5%)                              │
  │    vocal: 0.64   (weight: 30.0%)                              │
  └──────────────────────────────────────────────────────────────┘


KEY INNOVATIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. ADAPTIVE WEIGHTING: Modality weights adjust based on signal quality
2. SIGNAL AGREEMENT: Confidence reflects how well modalities agree
3. TEMPORAL SMOOTHING: 5-sample window prevents jitter
4. GRACEFUL DEGRADATION: Works with any subset of modalities (1, 2, or 3)
5. NEURODIVERSITY READY: Thresholds can be adjusted per child profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

This is getting quite long. Let me continue creating the remaining figures in the next response. Should I proceed with creating Figure 6 (Behavioral Spectrum Generation) and the remaining diagrams?