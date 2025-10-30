# ML Integration Guide

**Bolt 2.1 - Core ML Infrastructure**
**NeuroGuide iOS Application**

## Overview

This guide explains how to integrate new ML models into the NeuroGuide app using the Core ML infrastructure.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Adding a New Model](#adding-a-new-model)
3. [Running Inference](#running-inference)
4. [Performance Monitoring](#performance-monitoring)
5. [Privacy Guarantees](#privacy-guarantees)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

The ML infrastructure consists of 4 core services:

### 1. MLModelService
- **Purpose:** Load, unload, and run Core ML models
- **Implementation:** `MLModelManager.shared`
- **Key Features:**
  - Lazy loading with caching
  - Automatic performance tracking
  - Thread-safe operations
  - Memory management

### 2. DeviceCapabilityService
- **Purpose:** Detect device capabilities and recommend model quality
- **Implementation:** `DeviceCapabilityManager.shared`
- **Key Features:**
  - Neural Engine detection
  - Performance tier classification (high/medium/low)
  - Memory availability checking
  - Model requirement validation

### 3. ModelPerformanceMonitor
- **Purpose:** Track ML performance metrics
- **Implementation:** `PerformanceMonitor.shared`
- **Key Features:**
  - Latency tracking (average, P95)
  - Memory usage monitoring
  - Battery impact estimation
  - Performance alerts

### 4. PrivacyService
- **Purpose:** Verify on-device processing guarantees
- **Implementation:** `PrivacyManager.shared`
- **Key Features:**
  - Network activity monitoring
  - Privacy compliance verification
  - Privacy badge generation

---

## Adding a New Model

### Step 1: Define Model Type

Add your model to `MLModelType.swift`:

```swift
enum MLModelType: String, CaseIterable {
    case poseDetection = "pose_detection"
    case vocalAffect = "vocal_affect"
    case facialExpression = "facial_expression"
    case parentStress = "parent_stress"
    case yourNewModel = "your_model_name" // ADD HERE

    var displayName: String {
        switch self {
        case .yourNewModel: return "Your Model Name"
        // ...
        }
    }

    var latencyTarget: TimeInterval {
        switch self {
        case .yourNewModel: return 0.100 // 100ms target
        // ...
        }
    }

    var modelFileName: String {
        switch self {
        case .yourNewModel: return "YourModel"
        // ...
        }
    }

    var isAvailable: Bool {
        switch self {
        case .yourNewModel: return true // Set to false until ready
        // ...
        }
    }
}
```

### Step 2: Define Model Requirements

Add requirements to `ModelRequirements.swift`:

```swift
extension ModelRequirements {
    static var yourNewModel: ModelRequirements {
        return ModelRequirements(
            minimumIOSVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0),
            requiresNeuralEngine: false,
            minimumMemoryBytes: 100 * 1024 * 1024, // 100MB
            modelSizeBytes: 20 * 1024 * 1024, // 20MB
            recommendedQuality: .medium,
            requiresGPU: true,
            expectedInferenceFrequency: 10.0 // 10 inferences per second
        )
    }
}
```

### Step 3: Add Core ML Model to Bundle

1. Export your model as `.mlmodel` or `.mlpackage`
2. Add to Xcode project: `NeuroGuideApp/Core/ML/Resources/`
3. Ensure target membership includes `NeuroGuideApp`
4. File name should match `modelFileName` from Step 1

### Step 4: Update MLModelManager

Add model requirements to `getRequirements(for:)` method:

```swift
private func getRequirements(for type: MLModelType) -> ModelRequirements {
    switch type {
    case .yourNewModel:
        return .yourNewModel
    // ... other cases
    }
}
```

### Step 5: Set Model as Available

Once model file is added and tested, set `isAvailable = true` in `MLModelType.swift`.

---

## Running Inference

### Basic Inference Pattern

```swift
import CoreML

class YourViewModel: ObservableObject {
    private let modelService: MLModelService = MLModelManager.shared

    func processData(input: YourInputType) async throws -> YourOutputType {
        // 1. Create MLFeatureProvider input
        let mlInput = try createMLInput(from: input)

        // 2. Run inference
        let output = try await modelService.runInference(
            type: .yourNewModel,
            input: mlInput
        )

        // 3. Parse output
        let result = try parseMLOutput(output)

        return result
    }

    private func createMLInput(from input: YourInputType) throws -> MLFeatureProvider {
        // Convert your input to MLFeatureProvider
        // Example for image input:
        let imageFeature = try MLFeatureValue(cgImage: input.cgImage)
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "image": imageFeature
        ])
        return provider
    }

    private func parseMLOutput(_ output: MLFeatureProvider) throws -> YourOutputType {
        // Parse Core ML output to your domain type
        guard let predictions = output.featureValue(for: "predictions")?.multiArrayValue else {
            throw MLModelError.invalidOutput
        }

        // Process predictions...
        return YourOutputType(predictions: predictions)
    }
}
```

### Preloading Models

For better UX, preload models during app startup:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Preload critical models
        Task {
            await MLModelManager.shared.preloadModels([
                .yourNewModel,
                .facialExpression
            ])
        }

        return true
    }
}
```

### Error Handling

```swift
do {
    let result = try await modelService.runInference(type: .yourNewModel, input: input)
    // Handle success
} catch let error as MLModelError {
    switch error {
    case .modelNotFound(let type):
        // Model file missing from bundle
        print("Model not found: \(type)")

    case .modelLoadFailed(let type, let underlying):
        // Model failed to load
        print("Failed to load \(type): \(underlying)")

    case .inferenceFailed(let type, let underlying):
        // Inference failed
        print("Inference failed for \(type): \(underlying)")

    case .insufficientMemory:
        // Not enough memory to load model
        print("Insufficient memory")

    case .modelNotAvailable(let type):
        // Model not yet implemented
        print("Model not available: \(type)")

    case .invalidInput(let type, let reason):
        // Invalid input format
        print("Invalid input for \(type): \(reason)")

    case .modelNotLoaded(let type):
        // Model needs to be loaded first
        print("Model not loaded: \(type)")
    }
} catch {
    // Other errors
    print("Unexpected error: \(error)")
}
```

---

## Performance Monitoring

### Checking Performance Metrics

```swift
// Get latest metrics for a model
if let metrics = modelService.getPerformanceMetrics(for: .yourNewModel) {
    print("Latency: \(metrics.latencyMs)ms")
    print("Memory: \(metrics.memoryMB)MB")
    print("Meets target: \(metrics.meetsLatencyTarget)")
}

// Get aggregated statistics
let monitor = PerformanceMonitor.shared
if let stats = monitor.getStatistics(for: .yourNewModel) {
    print("Average latency: \(stats.averageLatency)s")
    print("P95 latency: \(stats.p95Latency)s")
    print("Target compliance: \(stats.targetComplianceRate)%")
}
```

### Performance Targets

Each model has a latency target defined in `MLModelType.latencyTarget`:

- **Pose Detection:** 50ms (20 FPS)
- **Vocal Affect:** 100ms (10 Hz)
- **Facial Expression:** 200ms (5 Hz)
- **Parent Stress:** 200ms (5 Hz)

The monitor tracks compliance with these targets and generates alerts if models consistently miss targets.

### Subscribing to Performance Alerts

```swift
class YourViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        PerformanceMonitor.shared.alertPublisher
            .sink { [weak self] alert in
                self?.handlePerformanceAlert(alert)
            }
            .store(in: &cancellables)
    }

    private func handlePerformanceAlert(_ alert: PerformanceAlert) {
        switch alert.severity {
        case .critical:
            // Critical performance issue - consider degrading quality
            print("CRITICAL: \(alert.message)")
        case .warning:
            // Warning - monitor situation
            print("WARNING: \(alert.message)")
        }
    }
}
```

### Dev Dashboard

For debugging, use the Performance Dashboard (dev builds only):

```swift
#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @State private var showPerformanceDashboard = false

    var body: some View {
        Button("Show ML Performance") {
            showPerformanceDashboard = true
        }
        .sheet(isPresented: $showPerformanceDashboard) {
            PerformanceDashboardView()
        }
    }
}
#endif
```

The dashboard shows:
- Device information
- Real-time battery impact
- Per-model statistics
- Active performance alerts

---

## Privacy Guarantees

### Verifying Privacy Status

```swift
let privacyService = PrivacyManager.shared

// Start monitoring
privacyService.startNetworkMonitoring()

// Check privacy status
let status = privacyService.getPrivacyStatus()
print("Processed locally: \(status.isProcessedLocally)")
print("Network activity: \(status.networkActivityDetected)")
print("Badge: \(status.badgeText)")

// Verify compliance
let verification = privacyService.verifyPrivacyStatus()
print("Compliance level: \(verification.complianceLevel)")
print("Passing: \(verification.isPassing)")

// Stop monitoring
privacyService.stopNetworkMonitoring()
```

### Privacy Badge

Display privacy status to users:

```swift
struct YourView: View {
    @State private var privacyBadge = ""

    var body: some View {
        VStack {
            Text(privacyBadge)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            privacyBadge = PrivacyManager.shared.showPrivacyBadge()
        }
    }
}
```

Expected badge text:
- **"🔒 Processing Locally"** - All privacy guarantees met
- **"⚠️ Privacy Check Failed"** - Privacy issue detected

---

## Testing

### Unit Testing Your Model Integration

```swift
import XCTest
@testable import NeuroGuideApp

final class YourModelTests: XCTestCase {
    var modelService: MLModelService!

    override func setUp() {
        super.setUp()
        modelService = MLModelManager.shared
    }

    override func tearDown() {
        modelService.unloadModel(type: .yourNewModel)
        super.tearDown()
    }

    func testModelLoading() async throws {
        let model = try await modelService.loadModel(type: .yourNewModel)
        XCTAssertNotNil(model)
        XCTAssertTrue(modelService.isModelLoaded(type: .yourNewModel))
    }

    func testInferencePerformance() async throws {
        let input = createTestInput()
        let startTime = Date()

        _ = try await modelService.runInference(type: .yourNewModel, input: input)

        let latency = Date().timeIntervalSince(startTime)
        let target = MLModelType.yourNewModel.latencyTarget

        XCTAssertLessThan(latency, target, "Inference should meet latency target")
    }

    func testDeviceCapability() {
        let deviceCapability = DeviceCapabilityManager.shared
        let requirements = ModelRequirements.yourNewModel

        let canRun = deviceCapability.canRunModel(requirements: requirements)
        XCTAssertTrue(canRun, "Device should meet model requirements")
    }
}
```

### Integration Testing

Test your model with real data:

```swift
func testRealWorldInference() async throws {
    // Load test data
    guard let testImage = UIImage(named: "test_image") else {
        XCTFail("Test image not found")
        return
    }

    // Create input
    let input = try createMLInput(from: testImage)

    // Run inference
    let output = try await modelService.runInference(type: .yourNewModel, input: input)

    // Validate output
    let result = try parseMLOutput(output)
    XCTAssertNotNil(result)

    // Check performance
    let metrics = modelService.getPerformanceMetrics(for: .yourNewModel)
    XCTAssertNotNil(metrics)
    XCTAssertTrue(metrics!.meetsLatencyTarget)
}
```

---

## Troubleshooting

### Model Not Found Error

**Problem:** `MLModelError.modelNotFound`

**Solution:**
1. Check model file is in bundle: `NeuroGuideApp/Core/ML/Resources/`
2. Verify file name matches `MLModelType.modelFileName`
3. Ensure target membership includes `NeuroGuideApp`
4. Check file extensions: `.mlmodel`, `.mlmodelc`, or `.mlpackage`

### Model Load Failed

**Problem:** `MLModelError.modelLoadFailed`

**Solution:**
1. Check iOS version meets `ModelRequirements.minimumIOSVersion`
2. Verify available memory meets `ModelRequirements.minimumMemoryBytes`
3. Check model compilation: Try deleting derived data
4. Validate model format: Re-export from Create ML or Core ML Tools

### Inference Failed

**Problem:** `MLModelError.inferenceFailed`

**Solution:**
1. Validate input shape matches model expectations
2. Check input value ranges (normalization)
3. Verify input feature names match model
4. Review Core ML model metadata in Xcode

### Performance Issues

**Problem:** High latency, exceeding targets

**Solution:**
1. Check device performance tier: Use `DeviceCapabilityManager.shared.getPerformanceTier()`
2. Consider quality degradation: Switch to `.medium` or `.low` quality models
3. Review memory usage: Unload unused models
4. Profile with Instruments: Use "Core ML" instrument
5. Check Neural Engine usage: Verify `supportsNeuralEngine()` returns true

### Memory Warnings

**Problem:** App receiving memory warnings

**Solution:**
1. Unload unused models: `modelService.unloadAllModels()`
2. Reduce model size: Use quantization or pruning
3. Implement adaptive quality: Degrade to lower quality models
4. Check for leaks: Profile with Memory Graph Debugger

### Privacy Check Failed

**Problem:** `privacyStatus.privacyGuaranteeMet == false`

**Solution:**
1. Ensure no network calls during ML processing
2. Check for analytics/telemetry during inference
3. Verify storage location is `.local`
4. Review third-party SDK network activity

---

## Additional Resources

- [Apple Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Core ML Model Optimization](https://developer.apple.com/documentation/coreml/optimizing_core_ml_performance)
- [Neural Engine Performance Guide](https://developer.apple.com/documentation/coreml/core_ml_api/optimizing_core_ml_performance/using_the_neural_engine)
- [NeuroGuide ML Performance Targets](./PERFORMANCE_TARGETS.md)
- [NeuroGuide Privacy Architecture](./PRIVACY_ARCHITECTURE.md)

---

**Last Updated:** 2025-10-22
**Bolt Version:** 2.1
**Author:** AI-DLC
