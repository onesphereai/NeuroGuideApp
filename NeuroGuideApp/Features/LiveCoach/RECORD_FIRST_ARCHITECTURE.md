# Live Coach Record-First Architecture

## Overview
Transform Live Coach from real-time processing to a record-first approach where:
1. Parent records a 1-minute session with dual camera view
2. Video is processed after recording
3. Results show child behavior spectrum, arousal timeline, and coaching suggestions
4. Parent receives emotional regulation guidance

## Architecture Changes

### Flow Comparison

**OLD FLOW (Real-time)**
```
Start Session → Real-time Camera → Live ML Processing → Instant Suggestions
```

**NEW FLOW (Record-first)**
```
Start Session → Record (1 min) → Process Video → Show Results
                    ↓                   ↓            ↓
             Dual Camera View    ML Analysis    Spectrum + Graph + Advice
```

### Three-Stage UI

#### Stage 1: Recording (0-60 seconds)
- Dual camera view (child + parent)
- Recording timer countdown (60s max)
- Stop button to end early
- Recording indicator (red dot)

#### Stage 2: Processing (Variable duration)
- Processing animation/progress
- "Analyzing session..." message
- Estimated time remaining
- Cannot cancel (already recorded)

#### Stage 3: Results
- **Child Behavior Spectrum**
  - Visual color spectrum based on arousal levels over time
  - Uses child's profile color as base
  - Shows intensity/frequency of different arousal states

- **Arousal Timeline Graph**
  - X-axis: Time (0-60s)
  - Y-axis: Arousal level (Shutdown → Red)
  - Line graph showing arousal changes
  - Colored zones for each arousal band

- **Parent Emotional State**
  - Detected parent emotions during session
  - Regulation advice specific to parent state
  - "You seemed stressed at [timestamp]"

- **Coaching Suggestions**
  - Contextual advice based on child's behavior patterns
  - Resources and strategies
  - Helpful/Not Helpful feedback

## New Components

### 1. SessionRecordingManager
```swift
class SessionRecordingManager {
    - recordDualCamera(maxDuration: 60)
    - stopRecording()
    - getRecordedVideo() -> URL
    - getFrameTimestamps() -> [TimeInterval]
}
```

### 2. VideoProcessingPipeline
```swift
class VideoProcessingPipeline {
    - processRecording(videoURL: URL, childID: UUID) async throws -> SessionAnalysisResult
    - extractFrames(from: URL) -> [CVPixelBuffer]
    - analyzeChildBehavior(frames: [CVPixelBuffer]) -> [ArousalBandSample]
    - analyzeParentEmotion(frames: [CVPixelBuffer]) -> [EmotionSample]
    - generateCoachingSuggestions() -> [CoachingSuggestion]
}
```

### 3. SessionAnalysisResult
```swift
struct SessionAnalysisResult {
    let childBehaviorSpectrum: BehaviorSpectrum
    let arousalTimeline: [ArousalBandSample]
    let parentEmotionTimeline: [EmotionSample]
    let coachingSuggestions: [CoachingSuggestion]
    let duration: TimeInterval
    let recordedAt: Date
}

struct ArousalBandSample {
    let timestamp: TimeInterval  // 0-60s
    let band: ArousalBand
    let confidence: Double
}

struct EmotionSample {
    let timestamp: TimeInterval
    let emotion: ParentEmotion
    let confidence: Double
}
```

### 4. BehaviorSpectrum
```swift
struct BehaviorSpectrum {
    let profileColor: Color  // From child profile
    let shutdownPercentage: Double
    let greenPercentage: Double
    let yellowPercentage: Double
    let orangePercentage: Double
    let redPercentage: Double

    // Visual representation
    var spectrumColors: [Color] {
        // Blend profile color with arousal intensities
    }
}
```

### 5. ArousalTimelineGraph (SwiftUI View)
```swift
struct ArousalTimelineGraph: View {
    let samples: [ArousalBandSample]
    let duration: TimeInterval

    var body: some View {
        // X-axis: 0-60s with markers every 10s
        // Y-axis: 5 arousal bands
        // Line chart with colored zones
        // Tap to see details at specific timestamp
    }
}
```

### 6. Child Profile Color Selection
```swift
extension ChildProfile {
    var profileColor: Color {
        // Add to profile creation
    }
}

// Update ProfileCreationView to include color picker
```

## Implementation Steps

### Phase 1: Recording Infrastructure
1. Create `SessionRecordingManager`
2. Implement dual camera recording with 60s max
3. Add recording UI with countdown timer
4. Store video temporarily for processing

### Phase 2: Processing Pipeline
1. Create `VideoProcessingPipeline`
2. Extract frames at ~3fps (same as current processing)
3. Run ML models on extracted frames
4. Generate arousal timeline
5. Generate parent emotion timeline
6. Create coaching suggestions

### Phase 3: Results Visualization
1. Create `BehaviorSpectrum` model
2. Build spectrum visualization component
3. Create `ArousalTimelineGraph` component
4. Add parent emotion summary
5. Show coaching suggestions

### Phase 4: Profile Enhancement
1. Add color selection to child profile
2. Update `ChildProfile` model
3. Update profile creation UI
4. Use profile color in spectrum

### Phase 5: ViewModel Refactoring
1. Add recording state management
2. Add processing state management
3. Add results state management
4. Update session lifecycle
5. Handle errors at each stage

### Phase 6: View Updates
1. Split view into 3 stages
2. Recording stage UI
3. Processing stage UI
4. Results stage UI
5. Navigation between stages

## Data Privacy

- **Video Storage**: Temporary only, deleted after processing
- **Processed Data**: Keep arousal timeline, suggestions (not raw video)
- **On-Device**: All ML processing remains on-device
- **No Cloud**: Video never leaves device
- **User Control**: Option to save or discard session results

## Performance Considerations

- **Recording**: Use efficient codec (H.264)
- **Processing**: Background thread, show progress
- **Memory**: Process frames in batches
- **Storage**: Clean up temp videos after processing
- **Battery**: Warn if battery < 20%

## User Experience

### Recording Stage
- Clear countdown timer
- Visual feedback (pulsing red dot)
- "Tap to stop early" guidance
- Both camera previews visible
- Child name displayed

### Processing Stage
- Animated progress indicator
- "Analyzing session data..." message
- Estimated time (e.g., "About 30 seconds remaining")
- Cannot navigate away

### Results Stage
- Tab view for different analyses
- Save session option
- Share results option
- Start new session button
- View history button

## Error Handling

- **Storage full**: Warn before recording
- **Camera failure**: Show error, allow retry
- **Processing failure**: Show error, offer to re-process
- **Low battery**: Warn, allow to continue or cancel

## Testing Strategy

1. **Unit Tests**: Processing pipeline, spectrum calculation
2. **Integration Tests**: End-to-end recording → processing → results
3. **UI Tests**: User flow through all three stages
4. **Performance Tests**: 60s recording, processing time
5. **Memory Tests**: No leaks, proper cleanup

## Migration Path

1. Keep current real-time code as fallback
2. Add feature flag for record-first mode
3. Test with pilot users
4. Gradually roll out
5. Eventually remove real-time code

## Success Metrics

- Recording completion rate: >90%
- Processing success rate: >95%
- Processing time: <60 seconds for 60s video
- User satisfaction: >4/5 rating
- Spectrum accuracy: Validated by parents >80%
