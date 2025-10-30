# ADR-001: Core ML Framework Selection

**Date:** 2025-10-22
**Status:** Accepted
**Context:** Bolt 2.1 - Core ML Infrastructure
**Deciders:** AI-DLC, Product Team

---

## Context

NeuroGuide requires on-device ML processing to analyze:
- Child pose/movement during play sessions
- Vocal affect from speech
- Facial expressions
- Parent stress indicators

The solution must prioritize privacy (no cloud uploads), performance (real-time processing), and battery efficiency.

## Decision Drivers

1. **Privacy:** All processing must happen on-device
2. **Performance:** Real-time inference (20-50ms latency)
3. **Battery:** < 10% drain per 30-minute session
4. **iOS Integration:** Native iOS framework preferred
5. **Hardware Acceleration:** Leverage Neural Engine if available
6. **Development Speed:** Fast MVP delivery required

## Options Considered

### Option 1: Apple Core ML (SELECTED)

**Pros:**
- ✅ First-party iOS framework
- ✅ Automatic Neural Engine optimization
- ✅ 100% on-device processing (privacy guarantee)
- ✅ Excellent battery efficiency
- ✅ Swift/Objective-C native integration
- ✅ Supports all major model formats (Convert from TensorFlow, PyTorch, etc.)
- ✅ Xcode integration and debugging tools
- ✅ Mature and well-documented

**Cons:**
- ❌ iOS/macOS only (not cross-platform)
- ❌ Limited model debugging compared to Python
- ❌ Requires model conversion from training frameworks

### Option 2: TensorFlow Lite

**Pros:**
- ✅ Cross-platform (iOS, Android, embedded)
- ✅ Large community and model zoo
- ✅ Direct TensorFlow model deployment

**Cons:**
- ❌ No Neural Engine support (slower inference)
- ❌ Higher battery consumption
- ❌ Third-party dependency (maintenance risk)
- ❌ Less iOS-optimized

### Option 3: PyTorch Mobile

**Pros:**
- ✅ Direct PyTorch model deployment
- ✅ Cross-platform

**Cons:**
- ❌ No Neural Engine support
- ❌ Less mature than TensorFlow Lite
- ❌ Larger binary size
- ❌ Third-party dependency

### Option 4: ONNX Runtime

**Pros:**
- ✅ Model format interoperability
- ✅ Cross-platform

**Cons:**
- ❌ Limited iOS optimization
- ❌ No Neural Engine support
- ❌ Third-party dependency

## Decision

**We chose Apple Core ML** for the following reasons:

1. **Privacy by Design:** Core ML runs 100% on-device with no network dependencies, aligning perfectly with NeuroGuide's privacy-first architecture.

2. **Performance:** Core ML automatically optimizes models for Apple Silicon, leveraging:
   - Neural Engine (A13+): Best performance, lowest power
   - GPU: Fallback for older devices
   - CPU: Universal compatibility

3. **Battery Efficiency:** Apple-optimized inference achieves target < 10% drain per 30-minute session.

4. **Native Integration:** First-party framework with excellent Xcode tooling, Swift integration, and long-term iOS support.

5. **Development Speed:** No need to manage third-party dependencies, updates, or compatibility issues.

6. **Model Flexibility:** Core ML Tools allow conversion from TensorFlow, PyTorch, Keras, scikit-learn, etc.

## Consequences

### Positive

- **Privacy Guarantee:** Architectural enforcement of on-device processing
- **Optimal Performance:** Hardware-accelerated inference
- **Low Battery Impact:** Apple-optimized power consumption
- **Future-Proof:** First-party support for upcoming Apple hardware
- **Developer Experience:** Native Swift APIs, Xcode integration

### Negative

- **iOS Only:** Cannot reuse ML pipeline for Android (future consideration)
- **Model Conversion:** Requires converting models from training frameworks
- **Limited Debugging:** Less introspection than Python-based frameworks

### Mitigation Strategies

1. **Cross-Platform:** If Android support needed, evaluate TensorFlow Lite alongside Core ML
2. **Model Conversion:** Use Core ML Tools Python package for automated conversion
3. **Debugging:** Use Instruments "Core ML" template for profiling; test models in Python before conversion

## Implementation Notes

### Model Conversion Example

```python
import coremltools as ct

# Load TensorFlow model
tf_model = tf.keras.models.load_model('pose_detection.h5')

# Convert to Core ML
coreml_model = ct.convert(
    tf_model,
    inputs=[ct.ImageType(shape=(1, 224, 224, 3))],
    compute_units=ct.ComputeUnit.ALL  # Neural Engine + GPU + CPU
)

# Save
coreml_model.save('PoseDetection.mlmodel')
```

### Swift Integration

```swift
import CoreML

// Load model
let model = try await MLModelManager.shared.loadModel(type: .poseDetection)

// Run inference
let output = try await model.prediction(from: input)
```

## Validation

- [x] Core ML meets all latency targets (verified in testing)
- [x] Neural Engine acceleration available on iPhone 11+ (A13+)
- [x] Zero network calls during inference (privacy verified)
- [x] Battery impact < 10% per 30-minute session (measured in testing)
- [x] Models load in < 1 second (verified)

## References

- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Core ML Tools](https://apple.github.io/coremltools/)
- [Neural Engine Performance Guide](https://developer.apple.com/documentation/coreml/core_ml_api/optimizing_core_ml_performance/using_the_neural_engine)
- [US-052: On-Device Model Execution](../../REQUIREMENTS.md)
- [US-045: Local-by-Default Processing](../../REQUIREMENTS.md)

---

**Revisit Date:** 2026-01-01 (if Android support needed)
