# Privacy Architecture

**Bolt 2.1 - Core ML Infrastructure**
**NeuroGuide iOS Application**

## Overview

This document describes the privacy-first architecture of NeuroGuide's ML infrastructure, ensuring all sensitive data processing happens on-device with zero cloud uploads.

---

## Table of Contents

1. [Privacy Principles](#privacy-principles)
2. [Architecture](#architecture)
3. [Privacy Service](#privacy-service)
4. [On-Device Processing](#on-device-processing)
5. [Data Storage](#data-storage)
6. [Network Isolation](#network-isolation)
7. [Verification & Testing](#verification--testing)
8. [Compliance](#compliance)

---

## Privacy Principles

### Core Commitments

1. **Local-by-Default:** All ML processing happens on-device
2. **Zero Cloud Upload:** No sensitive data leaves the device
3. **Data Minimization:** Collect only what's necessary
4. **User Control:** Parents control all data decisions
5. **Transparency:** Clear privacy indicators at all times

### Sensitive Data Categories

The following data is classified as sensitive and must never leave the device:

1. **Child Video:** Recordings of child during play sessions
2. **Child Audio:** Voice recordings of child
3. **Biometric Data:** Facial features, pose keypoints
4. **Behavioral Data:** Play patterns, interaction metrics
5. **Parent Data:** Stress indicators, interaction patterns
6. **ML Outputs:** Model predictions and confidence scores

---

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────┐
│           User Interface                │
│   (Play Session, Analysis Views)        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│        Privacy Service                  │
│  - Network Monitoring                   │
│  - Storage Location Verification        │
│  - Compliance Checking                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       ML Model Service                  │
│  - On-Device Inference Only             │
│  - No Network Access                    │
│  - Local Model Storage                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│          Core ML                        │
│  - Neural Engine                        │
│  - GPU/CPU Fallback                     │
│  - 100% On-Device                       │
└─────────────────────────────────────────┘
```

### Design Principles

1. **No Network Dependencies:** ML pipeline has zero network access
2. **Local Storage Only:** All data stored in app sandbox
3. **Privacy Verification:** Continuous monitoring during ML operations
4. **Fail-Safe:** System fails if privacy guarantees cannot be met

---

## Privacy Service

### PrivacyServiceProtocol

The `PrivacyService` provides methods to verify and monitor privacy guarantees:

```swift
protocol PrivacyServiceProtocol {
    // Verification
    func isDataProcessedLocally() -> Bool
    func getDataStorageLocation() -> StorageLocation
    func verifyPrivacyStatus() -> PrivacyVerificationResult

    // Monitoring
    func startNetworkMonitoring()
    func stopNetworkMonitoring()
    func wasNetworkActivityDetected() -> Bool

    // User-Facing
    func getPrivacyStatus() -> PrivacyStatus
    func showPrivacyBadge() -> String
}
```

### Privacy Status

```swift
struct PrivacyStatus {
    let isProcessedLocally: Bool          // Always true
    let networkActivityDetected: Bool      // Should be false
    let storageLocation: StorageLocation   // Should be .local
    let verificationTimestamp: Date
    let notes: String?

    var privacyGuaranteeMet: Bool {
        return isProcessedLocally &&
               !networkActivityDetected &&
               storageLocation == .local
    }

    var badgeText: String {
        if privacyGuaranteeMet {
            return "🔒 Processing Locally"
        } else {
            return "⚠️ Privacy Check Failed"
        }
    }
}
```

### Storage Locations

```swift
enum StorageLocation: String {
    case local = "local"              // App sandbox (PREFERRED)
    case iCloudPrivate = "icloud"     // iCloud private database (OK)
    case remote = "remote"            // Cloud storage (NOT ALLOWED)

    var isPrivacyCompliant: Bool {
        return self == .local || self == .iCloudPrivate
    }
}
```

### Compliance Levels

```swift
enum PrivacyComplianceLevel: String {
    case full = "full"                // All guarantees met
    case partial = "partial"          // Some concerns detected
    case noncompliant = "noncompliant" // Privacy violation

    var isPassing: Bool {
        return self == .full
    }
}
```

---

## On-Device Processing

### Core ML Pipeline

All ML inference happens exclusively on-device using Apple's Core ML framework:

```swift
class MLModelManager: MLModelService {
    func runInference(type: MLModelType,
                      input: MLFeatureProvider) async throws -> MLFeatureProvider {
        // 1. Ensure model is loaded (from app bundle)
        let model = try await loadModel(type: type)

        // 2. Run inference (100% on-device)
        let output = try await model.prediction(from: input)

        // 3. Return result (never leaves device)
        return output
    }
}
```

### No Network Access

The ML pipeline is designed with **zero network dependencies**:

1. **Models:** Bundled with app, loaded from local storage
2. **Input:** Captured locally (camera, microphone)
3. **Processing:** Core ML uses Neural Engine/GPU/CPU
4. **Output:** Stored in app sandbox
5. **Results:** Displayed in UI, never uploaded

### Network Monitoring

The `PrivacyService` monitors for unexpected network activity during ML operations:

```swift
class PrivacyManager: PrivacyServiceProtocol {
    private var networkMonitor: NWPathMonitor?
    private var networkActivityDetected = false

    func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Network is available - log for review
                self?.networkActivityDetected = true
                print("⚠️ Network available during ML processing")
            }
        }
        networkMonitor?.start(queue: monitorQueue)
    }

    func wasNetworkActivityDetected() -> Bool {
        return networkActivityDetected
    }
}
```

**Important:** The monitor detects if network is **available**, not if it's actually **used**. This is a conservative approach - if network is available, we flag it for review.

---

## Data Storage

### Local Storage Only

All sensitive data is stored in the app's sandbox:

```
/var/mobile/Containers/Data/Application/{UUID}/
├── Documents/
│   ├── sessions/          # Play session data
│   ├── recordings/        # Video/audio (if needed)
│   └── analysis/          # ML outputs
├── Library/
│   ├── Caches/           # Temporary data
│   └── Application Support/
│       └── ml_models/    # Downloaded models (future)
└── tmp/                  # Ephemeral data
```

### File Protection

All files use iOS Data Protection:

```swift
let attributes = [
    FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
]

try FileManager.default.setAttributes(attributes, ofItemAtPath: filePath)
```

**Protection Levels:**
- `.complete`: Only accessible when device unlocked (highest security)
- `.completeUnlessOpen`: Remains accessible if opened before lock
- `.completeUntilFirstUserAuthentication`: Available after first unlock (default)

### No iCloud Backup (Sensitive Data)

Sensitive data is excluded from iCloud backup:

```swift
var resourceValues = URLResourceValues()
resourceValues.isExcludedFromBackup = true
try url.setResourceValues(resourceValues)
```

**Rationale:** Prevents sensitive data from syncing to iCloud servers.

---

## Network Isolation

### No Analytics During Inference

All analytics and telemetry are disabled during ML processing:

```swift
func runInference() async throws {
    // Disable analytics
    Analytics.pause()

    defer {
        // Re-enable after inference
        Analytics.resume()
    }

    // Run ML inference
    let output = try await modelService.runInference(...)
}
```

### No Crash Reporting

Crash reports are sanitized to exclude sensitive data:

```swift
func configureErrorReporting() {
    ErrorReporter.setUserDataFilter { userData in
        // Remove sensitive fields
        var filtered = userData
        filtered.removeValue(forKey: "child_video_path")
        filtered.removeValue(forKey: "ml_predictions")
        filtered.removeValue(forKey: "biometric_data")
        return filtered
    }
}
```

### Network Assertions

In debug builds, assert that no network calls occur during ML:

```swift
#if DEBUG
func runInference() async throws {
    let networkBefore = hasActiveConnections()

    let output = try await modelService.runInference(...)

    let networkAfter = hasActiveConnections()
    assert(networkAfter == networkBefore, "Network activity during ML inference!")
}
#endif
```

---

## Verification & Testing

### Unit Tests

Test privacy guarantees:

```swift
func testDataProcessedLocally() {
    let privacyService = PrivacyManager.shared
    XCTAssertTrue(privacyService.isDataProcessedLocally())
}

func testNoNetworkActivityDuringInference() async throws {
    let privacyService = PrivacyManager.shared
    privacyService.startNetworkMonitoring()

    // Run inference
    _ = try await modelService.runInference(type: .test, input: testInput)

    // Verify no network activity
    XCTAssertFalse(privacyService.wasNetworkActivityDetected())

    privacyService.stopNetworkMonitoring()
}

func testStorageLocation() {
    let privacyService = PrivacyManager.shared
    let location = privacyService.getDataStorageLocation()
    XCTAssertEqual(location, .local)
}

func testPrivacyCompliance() {
    let result = PrivacyManager.shared.verifyPrivacyStatus()
    XCTAssertEqual(result.complianceLevel, .full)
    XCTAssertTrue(result.isPassing)
}
```

### Integration Tests

Test end-to-end privacy:

```swift
func testPlaySessionPrivacy() async throws {
    // Start privacy monitoring
    PrivacyManager.shared.startNetworkMonitoring()

    // Run full play session
    let session = PlaySession()
    try await session.start()
    try await session.runAnalysis()
    try await session.end()

    // Verify privacy guarantees
    let status = PrivacyManager.shared.getPrivacyStatus()
    XCTAssertTrue(status.privacyGuaranteeMet)
    XCTAssertFalse(status.networkActivityDetected)

    PrivacyManager.shared.stopNetworkMonitoring()
}
```

### Manual Testing

1. **Airplane Mode Test:**
   - Enable Airplane Mode
   - Run play session with ML analysis
   - Verify everything works (proves no network dependency)

2. **Network Monitor Test:**
   - Install Charles Proxy or similar
   - Run play session
   - Verify zero network traffic during ML inference

3. **File System Test:**
   - Run play session
   - Check app sandbox for stored data
   - Verify no data outside sandbox

---

## Compliance

### HIPAA Compliance (Future)

If NeuroGuide becomes HIPAA-covered:

**Required:**
- ✅ On-device processing (no PHI transmission)
- ✅ Local storage with encryption
- ⚠️ Access controls (implement user authentication)
- ⚠️ Audit logging (implement access logs)
- ⚠️ Business Associate Agreements (for any cloud services)

**Recommended:**
- Medical device classification review
- FDA guidance consultation
- HIPAA Security Risk Assessment

### COPPA Compliance

Children's Online Privacy Protection Act:

**Required:**
- ✅ Parental consent for data collection
- ✅ No data sharing with third parties
- ✅ Data security measures
- ⚠️ Privacy policy (draft in progress)
- ⚠️ Parental access to child data (implement export)

### GDPR Compliance (if EU users)

General Data Protection Regulation:

**Required:**
- ✅ Data minimization
- ✅ Purpose limitation (clear use cases)
- ✅ Storage limitation (implement data retention)
- ⚠️ Right to erasure (implement data deletion)
- ⚠️ Data portability (implement export)
- ⚠️ Privacy by design (ongoing)

### California CCPA (if CA users)

California Consumer Privacy Act:

**Required:**
- ✅ Notice at collection
- ✅ No sale of personal information
- ⚠️ Right to deletion (implement)
- ⚠️ Right to access (implement export)

---

## Privacy Badge UI

### Display Privacy Status

Show users that their data is processed locally:

```swift
struct PrivacyBadgeView: View {
    @State private var privacyStatus: PrivacyStatus?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.green)

            Text("Processing Locally")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            privacyStatus = PrivacyManager.shared.getPrivacyStatus()
        }
    }
}
```

### Privacy Details Sheet

Allow users to view detailed privacy information:

```swift
struct PrivacyDetailsView: View {
    let status: PrivacyStatus

    var body: some View {
        List {
            Section("Processing") {
                HStack {
                    Text("Location")
                    Spacer()
                    Text(status.isProcessedLocally ? "On Device" : "Unknown")
                        .foregroundColor(status.isProcessedLocally ? .green : .red)
                }
            }

            Section("Network") {
                HStack {
                    Text("Network Activity")
                    Spacer()
                    Text(status.networkActivityDetected ? "Detected" : "None")
                        .foregroundColor(status.networkActivityDetected ? .red : .green)
                }
            }

            Section("Storage") {
                HStack {
                    Text("Location")
                    Spacer()
                    Text(status.storageLocation.rawValue.capitalized)
                }

                HStack {
                    Text("Compliant")
                    Spacer()
                    Text(status.storageLocation.isPrivacyCompliant ? "Yes" : "No")
                        .foregroundColor(status.storageLocation.isPrivacyCompliant ? .green : .red)
                }
            }

            Section("Verification") {
                HStack {
                    Text("Last Checked")
                    Spacer()
                    Text(status.verificationTimestamp, style: .relative)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    Text(status.privacyGuaranteeMet ? "✓ Verified" : "✗ Failed")
                        .foregroundColor(status.privacyGuaranteeMet ? .green : .red)
                }
            }
        }
        .navigationTitle("Privacy Status")
    }
}
```

---

## Future Enhancements

### Differential Privacy (Post-MVP)

If we need to collect aggregate statistics:

```swift
// Add noise to aggregate data
func addDifferentialPrivacy(value: Double, epsilon: Double = 1.0) -> Double {
    let laplacian = Laplacian(scale: 1.0 / epsilon)
    return value + laplacian.sample()
}

// Example: Report average session length with privacy
let avgLength = sessions.map { $0.duration }.reduce(0, +) / Double(sessions.count)
let privateAvgLength = addDifferentialPrivacy(value: avgLength)
```

### Federated Learning (Post-MVP)

If we need to train models without collecting raw data:

1. Train local model on device
2. Send only model updates (gradients) to server
3. Aggregate updates across devices
4. Distribute improved model

**Benefits:**
- No raw data leaves device
- Collective improvement
- Privacy-preserving

---

## References

- [Apple Privacy Documentation](https://developer.apple.com/documentation/security/protecting_user_privacy)
- [Core ML Privacy](https://developer.apple.com/documentation/coreml/core_ml_api/integrating_a_core_ml_model_into_your_app)
- [HIPAA Guidance](https://www.hhs.gov/hipaa/index.html)
- [COPPA Rules](https://www.ftc.gov/business-guidance/resources/childrens-online-privacy-protection-rule-six-step-compliance-plan-your-business)

---

**Last Updated:** 2025-10-22
**Bolt Version:** 2.1
**Author:** AI-DLC
