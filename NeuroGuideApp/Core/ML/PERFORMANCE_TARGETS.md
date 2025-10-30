# ML Performance Targets

**Bolt 2.1 - Core ML Infrastructure**
**NeuroGuide iOS Application**

## Overview

This document defines performance targets for all ML models in the NeuroGuide app to ensure responsive user experience and acceptable battery impact.

---

## Performance Metrics

### 1. Inference Latency

**Definition:** Time from input submission to output availability

**Measurement:** Wall-clock time, includes:
- Model loading (first inference only)
- Input preprocessing
- Model inference
- Output postprocessing

**Target Percentiles:**
- **P50 (Median):** 50th percentile of all inferences
- **P95:** 95th percentile (max acceptable latency)
- **P99:** 99th percentile (rarely exceeded)

### 2. Memory Usage

**Definition:** Peak memory consumed during model inference

**Measurement:**
- Resident memory delta (before → after inference)
- Excludes base app memory footprint

**Limits:**
- **Per-model:** Defined in `ModelRequirements.minimumMemoryBytes`
- **Total concurrent:** Sum of all loaded models must stay under 500MB

### 3. Battery Impact

**Definition:** Estimated battery drain per 30-minute session

**Measurement:**
- Based on inference frequency × latency × compute unit
- Neural Engine: ~0.01% per 100ms
- GPU: ~0.02% per 100ms
- CPU: ~0.03% per 100ms

**Target:** < 10% battery drain per 30-minute session

---

## Model-Specific Targets

### Pose Detection Model

**Use Case:** Real-time motion tracking during play sessions

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Inference Frequency** | 20 FPS | Smooth motion tracking |
| **P50 Latency** | 30ms | Responsive feedback |
| **P95 Latency** | 50ms | Acceptable worst case |
| **P99 Latency** | 100ms | Rare spikes tolerable |
| **Memory Usage** | ≤ 50MB | Lightweight model |
| **Battery Impact** | 5% per 30min | Frequent inferences |
| **Model Size** | ≤ 5MB | Fast download/load |
| **Minimum iOS** | 15.0 | Wide compatibility |
| **Neural Engine** | Recommended | Performance boost |

**Quality Degradation Strategy:**
- **High devices (A15+):** Full 20 FPS
- **Medium devices (A14):** 15 FPS
- **Low devices (A13):** 10 FPS

---

### Vocal Affect Model

**Use Case:** Analyze speech patterns for emotional state

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Inference Frequency** | 10 Hz | Balance accuracy/performance |
| **P50 Latency** | 60ms | Real-time processing |
| **P95 Latency** | 100ms | Acceptable delay |
| **P99 Latency** | 150ms | Occasional spikes OK |
| **Memory Usage** | ≤ 100MB | Audio buffer + model |
| **Battery Impact** | 3% per 30min | Moderate frequency |
| **Model Size** | ≤ 15MB | Audio models larger |
| **Minimum iOS** | 16.0 | Sound Analysis framework |
| **Neural Engine** | Required | Audio processing |

**Quality Degradation Strategy:**
- **High devices:** 10 Hz, full feature set
- **Medium devices:** 5 Hz, reduced features
- **Low devices:** Fallback to rule-based

---

### Facial Expression Model

**Use Case:** Detect emotions from facial expressions

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Inference Frequency** | 5 FPS | Facial changes slower |
| **P50 Latency** | 100ms | User won't notice |
| **P95 Latency** | 200ms | Still imperceptible |
| **P99 Latency** | 300ms | Rare cases acceptable |
| **Memory Usage** | ≤ 150MB | Vision model + preprocessing |
| **Battery Impact** | 2% per 30min | Lower frequency |
| **Model Size** | ≤ 25MB | Computer vision model |
| **Minimum iOS** | 15.0 | Vision framework |
| **Neural Engine** | Recommended | Vision acceleration |

**Quality Degradation Strategy:**
- **High devices:** 5 FPS, 7 emotion classes
- **Medium devices:** 3 FPS, 5 emotion classes
- **Low devices:** 2 FPS, 3 emotion classes (happy/neutral/distressed)

---

### Parent Stress Model

**Use Case:** Analyze patterns to detect parent stress indicators

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Inference Frequency** | 0.2 Hz (every 5s) | Infrequent checks |
| **P50 Latency** | 100ms | Not time-critical |
| **P95 Latency** | 200ms | Acceptable lag |
| **P99 Latency** | 500ms | Worst case tolerable |
| **Memory Usage** | ≤ 80MB | Multimodal inputs |
| **Battery Impact** | 1% per 30min | Very low frequency |
| **Model Size** | ≤ 10MB | Lightweight model |
| **Minimum iOS** | 15.0 | Standard APIs |
| **Neural Engine** | Optional | CPU sufficient |

**Quality Degradation Strategy:**
- **All devices:** Single model, degradation not needed due to low frequency

---

## Device Performance Tiers

### High Tier
**Devices:** iPhone 13+, iPad Air (5th gen)+, iPad Pro (M1+)
**Processor:** A15 Bionic or newer
**Characteristics:**
- Neural Engine available
- ≥ 4GB RAM
- All models at highest quality
- No performance degradation needed

### Medium Tier
**Devices:** iPhone 12, iPad (9th gen), iPad Air (4th gen)
**Processor:** A14 Bionic
**Characteristics:**
- Neural Engine available
- 3-4GB RAM
- Slight quality reduction for heavy models
- Reduce FPS by 25% if needed

### Low Tier
**Devices:** iPhone 11, iPhone SE (2nd gen)
**Processor:** A13 Bionic
**Characteristics:**
- Neural Engine available
- 2-3GB RAM
- Significant quality reduction
- Reduce FPS by 50%
- Consider fallback to rule-based

---

## Monitoring and Alerting

### Performance Monitoring

The `PerformanceMonitor` tracks all inferences and generates alerts when targets are not met.

**Tracked Metrics:**
```swift
struct ModelPerformanceMetrics {
    let modelType: MLModelType
    let inferenceLatency: TimeInterval    // Wall-clock time
    let memoryUsage: Int64                // Bytes
    let batteryImpact: Double             // Estimated %
    let timestamp: Date
}
```

**Aggregated Statistics:**
```swift
struct PerformanceStatistics {
    let sampleCount: Int                  // Total inferences
    let averageLatency: TimeInterval      // Mean latency
    let p95Latency: TimeInterval          // 95th percentile
    let targetComplianceRate: Double      // % meeting target
}
```

### Alert Thresholds

**Critical Alerts:** (Severity: `.critical`)
- P95 latency > 2× target
- Memory usage > 150% of requirement
- Battery impact > 15% per 30min
- Target compliance rate < 80%

**Warning Alerts:** (Severity: `.warning`)
- P95 latency > 1.5× target
- Memory usage > 120% of requirement
- Battery impact > 12% per 30min
- Target compliance rate < 90%

**Example Alert:**
```swift
PerformanceAlert(
    severity: .critical,
    message: "Pose Detection P95 latency 120ms exceeds target 50ms",
    modelType: .poseDetection,
    timestamp: Date()
)
```

### Responding to Alerts

**When Critical Alert Fires:**

1. **Log and investigate:**
   ```swift
   PerformanceMonitor.shared.alertPublisher
       .sink { alert in
           print("🚨 \(alert.message)")
           // Log to analytics
       }
   ```

2. **Degrade quality if possible:**
   ```swift
   func handleCriticalAlert(_ alert: PerformanceAlert) {
       guard let modelType = alert.modelType else { return }

       // Switch to lower quality model
       let currentQuality = getCurrentQuality(for: modelType)
       if let lowerQuality = currentQuality.degrade() {
           switchToQuality(lowerQuality, for: modelType)
       }
   }
   ```

3. **Consider disabling model:**
   ```swift
   // Last resort: disable model temporarily
   if alert.severity == .critical && degradationFailed {
       MLModelManager.shared.unloadModel(type: modelType)
   }
   ```

---

## Testing Performance

### Unit Testing

Test that models meet latency targets:

```swift
func testPoseDetectionLatency() async throws {
    let startTime = Date()
    _ = try await modelService.runInference(type: .poseDetection, input: testInput)
    let latency = Date().timeIntervalSince(startTime)

    XCTAssertLessThan(latency, MLModelType.poseDetection.latencyTarget)
}
```

### Benchmark Testing

Run 100 inferences and check P95:

```swift
func testPoseDetectionP95() async throws {
    var latencies: [TimeInterval] = []

    for _ in 0..<100 {
        let start = Date()
        _ = try await modelService.runInference(type: .poseDetection, input: testInput)
        latencies.append(Date().timeIntervalSince(start))
    }

    latencies.sort()
    let p95Index = Int(Double(latencies.count) * 0.95)
    let p95Latency = latencies[p95Index]

    XCTAssertLessThan(p95Latency, MLModelType.poseDetection.latencyTarget)
}
```

### Memory Testing

Test memory usage stays within bounds:

```swift
func testMemoryUsage() async throws {
    let startMemory = getMemoryUsage()
    _ = try await modelService.runInference(type: .poseDetection, input: testInput)
    let endMemory = getMemoryUsage()

    let memoryDelta = endMemory - startMemory
    let requirement = ModelRequirements.poseDetection.minimumMemoryBytes

    XCTAssertLessThan(memoryDelta, requirement)
}
```

### Device Testing Matrix

Test on representative devices:

| Device | Tier | Test Focus |
|--------|------|------------|
| iPhone 15 Pro | High | All models at highest quality |
| iPhone 13 | High | Battery impact over 30min |
| iPhone 12 | Medium | Quality degradation |
| iPhone 11 | Low | Fallback behavior |
| iPhone SE (2nd) | Low | Minimum requirements |

---

## Optimization Strategies

### Model Optimization

1. **Quantization:**
   - Float32 → Float16: 2× smaller, minimal accuracy loss
   - Float16 → Int8: 4× smaller, some accuracy loss
   - Use Core ML Tools for quantization

2. **Pruning:**
   - Remove low-importance weights
   - 10-30% size reduction
   - May require retraining

3. **Neural Architecture Search (NAS):**
   - Find efficient architectures
   - MobileNetV3, EfficientNet
   - Balance accuracy vs. latency

4. **Knowledge Distillation:**
   - Train smaller "student" model
   - Learn from larger "teacher" model
   - Maintain accuracy with smaller size

### Inference Optimization

1. **Batch Processing:**
   - Process multiple inputs together
   - Better GPU utilization
   - Trade latency for throughput

2. **Input Preprocessing:**
   - Resize images efficiently (vImage)
   - Cache preprocessed inputs
   - Parallelize preprocessing

3. **Compute Units:**
   - `.all`: Neural Engine + GPU + CPU
   - `.cpuAndNeuralEngine`: Exclude GPU
   - `.cpuOnly`: Fallback for debugging

4. **Model Preloading:**
   - Load models during app launch
   - Avoid first-inference penalty
   - Balance with memory usage

### Device Optimization

1. **Adaptive Quality:**
   - Detect performance tier
   - Load appropriate model variant
   - Adjust inference frequency

2. **Thermal Management:**
   - Monitor device temperature
   - Reduce inference frequency when hot
   - Unload models if overheating

3. **Battery Awareness:**
   - Check battery level
   - Reduce quality in low-power mode
   - Disable non-critical models < 20%

---

## Acceptance Criteria

### Bolt 2.1 Performance Targets

**US-052: On-Device Model Execution**

- [x] All models load in < 1 second
- [x] P95 latency meets target for each model type
- [x] Memory usage stays within defined limits
- [x] No memory leaks (verified with Instruments)
- [x] Models unload properly on memory warning

**US-045: Local-by-Default Processing**

- [x] All ML processing happens on-device
- [x] No network calls during inference
- [x] Data never leaves device
- [x] Privacy badge shows "🔒 Processing Locally"

**Performance Dashboard (Dev Only)**

- [x] Real-time latency monitoring
- [x] Memory usage tracking
- [x] Battery impact estimation
- [x] Performance alerts display

---

## References

- [Apple Core ML Performance Best Practices](https://developer.apple.com/documentation/coreml/optimizing_core_ml_performance)
- [Neural Engine Performance Guide](https://developer.apple.com/documentation/coreml/core_ml_api/optimizing_core_ml_performance/using_the_neural_engine)
- [Core ML Model Optimization](https://apple.github.io/coremltools/)

---

**Last Updated:** 2025-10-22
**Bolt Version:** 2.1
**Author:** AI-DLC
