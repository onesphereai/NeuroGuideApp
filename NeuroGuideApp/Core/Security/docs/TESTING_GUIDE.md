# Security Testing Guide - iOS Simulator

**Bolt 2.2 - Data Encryption & Security**
**Date:** 2025-10-22

---

## Overview

This guide covers how to test all security features in the iOS Simulator. While some features (like Face ID/Touch ID) have limitations in the simulator, most functionality can be thoroughly tested.

---

## Prerequisites

### Required Tools
- Xcode 15.0+
- iOS Simulator (iOS 15.0+)
- NeuroGuide app installed in simulator

### Simulator Setup
```bash
# Launch simulator
open -a Simulator

# Or from Xcode: Xcode → Open Developer Tool → Simulator
```

---

## Part 1: Encryption Service Tests

### 1.1 Run Unit Tests

**From Xcode:**
```
1. Press Cmd+U to run all tests
2. Or: Product → Test
3. Watch test results in Test Navigator (Cmd+6)
```

**From Command Line:**
```bash
cd /Users/ammarkhalid/workspace/nureo-guide/NeuroGuideApp

# Run all tests
xcodebuild test \
  -scheme NeuroGuideApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

# Run only security tests
xcodebuild test \
  -scheme NeuroGuideApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
  -only-testing:NeuroGuideTests/EncryptionServiceTests \
  -only-testing:NeuroGuideTests/KeychainServiceTests \
  -only-testing:NeuroGuideTests/SecureStorageTests
```

**Expected Results:**
```
✅ EncryptionServiceTests: 29/29 tests passed
✅ KeychainServiceTests: 23/23 tests passed
✅ SecureStorageTests: 27/27 tests passed
```

### 1.2 Verify Encryption on Disk

**Test Steps:**
1. Run the app in simulator
2. Create some test data (child profile, session notes)
3. Find the app's data directory:

```bash
# Find the app container
xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data

# Example output:
# /Users/yourname/Library/Developer/CoreSimulator/Devices/{UUID}/data/Containers/Data/Application/{APP_UUID}

# Navigate to Documents/SecureStorage
cd "$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)/Documents/SecureStorage"

# List encrypted files
ls -la

# Try to read an encrypted file
cat app_settings.enc

# Expected: Binary garbage (encrypted data), not readable plaintext
```

**Expected Results:**
- Files exist in `Documents/SecureStorage/`
- Files have `.enc` extension
- Files contain binary data (not readable text)
- Cannot find plaintext strings like email addresses or names

---

## Part 2: Keychain Service Tests

### 2.1 Verify Keychain Storage

**Using Keychain Access App (macOS):**

The simulator uses the Mac's keychain, so you can inspect it:

```bash
# Open Keychain Access
open -a "Keychain Access"

# Search for: com.neuroguide
# You should see entries like:
# - com.neuroguide.storage.masterKey
# - com.neuroguide.app (if app lock enabled)
```

**Using Command Line:**

```bash
# List keychain items for NeuroGuide
security find-generic-password -s "com.neuroguide.storage"

# Expected output shows:
# keychain: "/Users/yourname/Library/Keychains/login.keychain-db"
# class: "genp"
# attributes:
#     "svce"<blob>="com.neuroguide.storage"
#     ...
```

### 2.2 Test Keychain Persistence

**Test Steps:**
1. Launch app in simulator
2. Enable app lock (creates keychain entry)
3. Quit app
4. Relaunch app
5. Verify: Master key still loaded (app doesn't crash, data still accessible)

**Script to Test:**
```bash
# Launch app
xcrun simctl launch booted com.neuroguide.NeuroGuideApp

# Wait a few seconds
sleep 5

# Terminate app
xcrun simctl terminate booted com.neuroguide.NeuroGuideApp

# Relaunch
xcrun simctl launch booted com.neuroguide.NeuroGuideApp

# Check logs
xcrun simctl spawn booted log show --predicate 'processImagePath contains "NeuroGuide"' --last 1m
```

---

## Part 3: Biometric Authentication (Face ID/Touch ID)

### 3.1 Simulator Limitations

**Important:** The simulator has limited biometric support:
- ✅ Can simulate Face ID/Touch ID availability
- ✅ Can test success/failure flows
- ❌ Cannot actually use your face or fingerprint
- ❌ Manual success/failure trigger via menu

### 3.2 Enable Face ID in Simulator

**Steps:**
1. Launch simulator (iPhone X or newer for Face ID)
2. Go to: **Features → Face ID → Enrolled**
3. This makes `biometricType()` return `.faceID`

**For Touch ID:**
1. Use iPhone 8 simulator or earlier
2. Go to: **Features → Touch ID → Enrolled**

### 3.3 Test Biometric Authentication Flow

**Test Steps:**
1. Launch NeuroGuide app
2. Go to: **Settings → Privacy & Data**
3. Enable **App Lock** toggle
4. Background the app: **Cmd+Shift+H** (go to home screen)
5. Wait 30+ seconds
6. Reopen app: **Tap app icon** or **Cmd+Shift+H** twice → select app
7. App should show lock screen with prompt

**Simulate Success:**
1. When lock screen appears
2. Go to: **Features → Face ID → Matching Face**
3. App should unlock

**Simulate Failure:**
1. When lock screen appears
2. Go to: **Features → Face ID → Non-matching Face**
3. Should show error, offer retry

**Alternative: Programmatic Testing**

Add this to your test code:
```swift
// In your test file
func testBiometricFlow() async throws {
    let manager = AppLockManager.shared

    // Enable biometric
    try manager.enableBiometric()

    // Lock app
    manager.lockApp()
    XCTAssertTrue(manager.isLocked)

    // In simulator, LAContext will fail with .biometryNotAvailable
    // or succeed if you use Features menu
}
```

### 3.4 Test Biometric Availability Detection

**Test Steps:**
1. Launch app
2. Go to: **Settings → Privacy & Data**
3. Check **Security** section

**Expected Results:**

**iPhone X+ Simulator (Face ID):**
```
✅ Shows "App Lock" toggle
✅ Shows Face ID icon
✅ Description: "Unlock app with Face ID"
```

**iPhone 8 Simulator (Touch ID):**
```
✅ Shows "App Lock" toggle
✅ Shows Touch ID icon (fingerprint)
✅ Description: "Unlock app with Touch ID"
```

**iPad Simulator (Varies):**
```
✅ Shows Touch ID or Face ID depending on model
```

**No Biometric:**
```
❌ Security section not shown
(or shows "Biometric authentication not available")
```

---

## Part 4: App Lock Testing

### 4.1 Test Lock on Background

**Manual Test:**
1. Launch app with app lock enabled
2. Navigate to any screen
3. Background app: **Cmd+Shift+H**
4. Wait 30+ seconds (lock timeout)
5. Return to app: **Cmd+Shift+H** twice → select app

**Expected Results:**
- Lock screen overlay appears
- Background content blurred
- Biometric prompt shown
- After auth success → app unlocks

### 4.2 Test Lock Timeout Variations

**Test Different Timeouts:**

Modify `AppLockManager.swift` temporarily:
```swift
// Change timeout for testing
private let lockTimeoutSeconds: TimeInterval = 5 // Was 30
```

Then test:
```
1. Background app
2. Wait 5 seconds (instead of 30)
3. Return to app
4. Verify: Lock screen appears
```

**Don't forget to change it back to 30 seconds!**

### 4.3 Test Lock on Launch

**Test Steps:**
1. Enable app lock
2. Fully terminate app: **Swipe up in app switcher**
3. Relaunch app from home screen

**Expected Results:**
- Lock screen appears immediately on launch
- Biometric prompt shown
- After success → proceeds to normal app flow

### 4.4 Test Background Privacy Screen

**Test Steps:**
1. Launch app
2. Navigate to a screen with sensitive data
3. Background app: **Cmd+Shift+H**
4. Open app switcher: **Cmd+Shift+H** twice

**Expected Results:**
- App preview is blurred (privacy protection)
- Cannot see sensitive data in app switcher

**Implementation Check:**
```swift
// NeuroGuideApp.swift should have:
.blur(radius: appLockManager.showLockScreen ? 20 : 0)
```

---

## Part 5: Secure Storage Integration Tests

### 5.1 Test Data Persistence

**Test Steps:**
1. Launch app
2. Create a child profile with test data:
   - Name: "Test Child"
   - Age: 5
   - Diagnosis: "Autism"
3. Quit app completely
4. Relaunch app
5. Verify: Profile still exists and data matches

**Verification:**
```bash
# Check encrypted file exists
cd "$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)/Documents/SecureStorage"
ls -la | grep child_profile

# Verify it's encrypted (not plaintext)
strings child_profile_*.enc | grep "Test Child"
# Expected: No output (strings should not find plaintext)
```

### 5.2 Test Data Deletion

**Test Steps:**
1. Create test data (profiles, sessions)
2. Go to: **Settings → Advanced → Reset All Data**
3. Confirm deletion
4. Verify: All data removed

**Verification:**
```bash
# Check SecureStorage directory
cd "$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)/Documents/SecureStorage"
ls -la

# Expected: Directory empty or only system files
```

### 5.3 Test Large Data Handling

**Test Steps:**
1. Create 50+ session notes
2. Add long text (1000+ characters) to notes
3. Navigate between screens
4. Verify: No crashes, reasonable performance

**Expected Results:**
- All data loads successfully
- Encryption/decryption fast (<100ms per operation)
- No memory issues

---

## Part 6: Data Protection on App Uninstall

### 6.1 Test App Uninstall Cleanup

**Test Steps:**
1. Note the app container path:
```bash
APP_PATH=$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)
echo $APP_PATH
```

2. Verify data exists:
```bash
ls -la "$APP_PATH/Documents/SecureStorage"
```

3. Uninstall app:
```bash
xcrun simctl uninstall booted com.neuroguide.NeuroGuideApp
```

4. Verify data deleted:
```bash
ls -la "$APP_PATH"
# Expected: "No such file or directory"
```

5. Verify keychain cleaned:
```bash
security find-generic-password -s "com.neuroguide.storage" 2>&1
# Expected: "The specified item could not be found in the keychain."
```

### 6.2 Test Reinstall (Fresh Start)

**Test Steps:**
1. Uninstall app
2. Reinstall from Xcode: **Cmd+R**
3. Launch app
4. Verify: No old data present (clean slate)

---

## Part 7: Performance Testing

### 7.1 Measure Encryption Performance

**Test Steps:**
1. Run app in Release mode (not Debug)
2. Enable performance testing
3. Use Instruments

**Using Instruments:**
```bash
# Build for profiling
xcodebuild -scheme NeuroGuideApp -configuration Release build

# Launch Instruments
open -a Instruments

# Choose: Time Profiler
# Run app and perform operations:
# - Create profile
# - Save settings
# - Load data
```

**Expected Performance:**
- Encryption: <5ms for typical data (<100KB)
- Decryption: <5ms for typical data
- Keychain access: <1ms
- No significant UI lag

### 7.2 Memory Testing

**Using Xcode Memory Graph:**
```
1. Run app
2. Create test data (profiles, sessions)
3. Navigate through app
4. Click Debug Memory Graph button (Xcode debug bar)
5. Check for leaks
```

**Expected Results:**
- No memory leaks
- Memory usage reasonable (<50MB for typical usage)
- No retain cycles in security components

---

## Part 8: Error Handling Tests

### 8.1 Test Wrong Key Scenario

**Add Debugging Code Temporarily:**
```swift
// In SecureStorageManager.swift (for testing only!)
func testWithWrongKey() throws {
    let wrongKey = Data(repeating: 0, count: 32)
    let fileURL = storageDirectory().appendingPathComponent("test.enc")
    let encrypted = try Data(contentsOf: fileURL)

    // This should throw
    _ = try encryptionService.decrypt(encryptedData: encrypted, using: wrongKey)
}
```

**Expected Result:**
- Throws `EncryptionError.authenticationFailed`
- App handles gracefully (doesn't crash)

### 8.2 Test Corrupted Data

**Corrupt an Encrypted File:**
```bash
# Find app container
APP_PATH=$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)

# Corrupt a file
cd "$APP_PATH/Documents/SecureStorage"
echo "corrupted" >> app_settings.enc
```

**Test Steps:**
1. Launch app
2. Try to load corrupted data
3. Verify: Error handled gracefully

**Expected Results:**
- App doesn't crash
- Shows error message
- Offers to reset/recover

### 8.3 Test Keychain Unavailable

**Simulate Keychain Failure:**

This is hard to simulate in the simulator, but you can test the error path:

```swift
// In tests
func testKeychainFailure() {
    let mockKeychain = MockKeychainService()
    mockKeychain.shouldFail = true

    let storage = SecureStorageManager(
        encryptionService: AESEncryptionService.shared,
        keychainService: mockKeychain,
        fileManager: .default
    )

    XCTAssertThrowsError(try storage.getMasterKey())
}
```

---

## Part 9: UI Testing

### 9.1 Create UI Test Suite

**Create New File:** `SecurityUITests.swift`

```swift
import XCTest

final class SecurityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testBiometricToggleAppears() throws {
        // Navigate to settings
        app.tabBars.buttons["Settings"].tap()

        // Tap Privacy & Data
        app.staticTexts["Privacy & Data"].tap()

        // Verify App Lock toggle exists
        let appLockToggle = app.switches["App Lock"]
        XCTAssertTrue(appLockToggle.exists)
    }

    func testEnableAppLock() throws {
        // Navigate to Privacy & Data
        app.tabBars.buttons["Settings"].tap()
        app.staticTexts["Privacy & Data"].tap()

        // Enable App Lock
        let toggle = app.switches["App Lock"]
        if !toggle.isSelected {
            toggle.tap()
        }

        // Verify toggle is on
        XCTAssertTrue(toggle.isSelected)
    }

    func testLockScreenAppears() throws {
        // Enable app lock first
        // ... (enable code)

        // Background app
        XCUIDevice.shared.press(.home)

        // Wait 30+ seconds (use shorter timeout for testing)
        sleep(35)

        // Reactivate app
        app.activate()

        // Verify lock screen appears
        let lockText = app.staticTexts["NeuroGuide is Locked"]
        XCTAssertTrue(lockText.waitForExistence(timeout: 5))
    }
}
```

**Run UI Tests:**
```bash
xcodebuild test \
  -scheme NeuroGuideApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:NeuroGuideUITests/SecurityUITests
```

---

## Part 10: Automated Testing Script

### 10.1 Complete Test Script

**Create:** `test_security.sh`

```bash
#!/bin/bash

set -e

echo "🔒 NeuroGuide Security Test Suite"
echo "================================="

# Configuration
SCHEME="NeuroGuideApp"
DEVICE="iPhone 15 Pro"
OS="17.0"

echo ""
echo "📱 Target: $DEVICE (iOS $OS)"
echo ""

# 1. Run unit tests
echo "1️⃣ Running unit tests..."
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  -only-testing:NeuroGuideTests/EncryptionServiceTests \
  -only-testing:NeuroGuideTests/KeychainServiceTests \
  -only-testing:NeuroGuideTests/SecureStorageTests \
  | xcpretty

echo "✅ Unit tests passed"

# 2. Check for encrypted files
echo ""
echo "2️⃣ Checking encrypted storage..."
APP_PATH=$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)
if [ -d "$APP_PATH/Documents/SecureStorage" ]; then
    echo "✅ SecureStorage directory exists"

    FILE_COUNT=$(ls "$APP_PATH/Documents/SecureStorage" | wc -l)
    echo "   Found $FILE_COUNT encrypted files"
else
    echo "⚠️  SecureStorage directory not found (app may not have run yet)"
fi

# 3. Check keychain
echo ""
echo "3️⃣ Checking keychain entries..."
if security find-generic-password -s "com.neuroguide.storage" &>/dev/null; then
    echo "✅ Master key found in keychain"
else
    echo "⚠️  Master key not found (app may not have initialized)"
fi

# 4. Performance check
echo ""
echo "4️⃣ Running performance tests..."
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  -only-testing:NeuroGuideTests/EncryptionServiceTests/testEncryptionPerformance \
  -only-testing:NeuroGuideTests/EncryptionServiceTests/testDecryptionPerformance \
  | xcpretty

echo "✅ Performance tests passed"

# 5. Build for release
echo ""
echo "5️⃣ Building release configuration..."
xcodebuild build \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  | xcpretty

echo "✅ Release build successful"

echo ""
echo "================================="
echo "✅ All security tests passed!"
echo ""
echo "Next steps:"
echo "  • Manual biometric testing (see TESTING_GUIDE.md)"
echo "  • Test on physical device"
echo "  • External security audit"
```

**Make executable and run:**
```bash
chmod +x test_security.sh
./test_security.sh
```

---

## Part 11: Testing Checklist

### Manual Testing Checklist

- [ ] **Encryption**
  - [ ] Data encrypted on disk (verified with `cat` command)
  - [ ] Plaintext not visible in encrypted files
  - [ ] Decryption works (app loads data correctly)

- [ ] **Keychain**
  - [ ] Master key stored in keychain
  - [ ] Key persists across app launches
  - [ ] Key deleted on app uninstall

- [ ] **Biometric Authentication**
  - [ ] Face ID detected on iPhone X+ simulator
  - [ ] Touch ID detected on iPhone 8 simulator
  - [ ] Toggle appears in settings
  - [ ] Can enable/disable app lock

- [ ] **App Lock**
  - [ ] Locks after 30s in background
  - [ ] Locks on app launch (when enabled)
  - [ ] Unlock prompt appears
  - [ ] Unlocks on biometric success
  - [ ] Background privacy screen (blur)

- [ ] **Data Management**
  - [ ] Profiles saved and loaded
  - [ ] Session data persists
  - [ ] Settings saved
  - [ ] Reset all data works
  - [ ] Data deleted on uninstall

- [ ] **Error Handling**
  - [ ] Handles decryption failures gracefully
  - [ ] Shows appropriate error messages
  - [ ] No crashes on corrupt data

- [ ] **Performance**
  - [ ] Encryption/decryption fast (<5ms)
  - [ ] No UI lag when saving/loading
  - [ ] Memory usage reasonable

### Automated Testing Checklist

- [ ] All 79 unit tests pass
- [ ] UI tests pass (if created)
- [ ] Performance tests within acceptable range
- [ ] Release build succeeds
- [ ] No warnings or errors

---

## Part 12: Known Simulator Limitations

### What Works in Simulator ✅
- Encryption/decryption
- Keychain storage
- File protection APIs
- SecureStorage operations
- App lock logic
- Biometric availability detection
- Unit tests (all 79 tests)

### What Doesn't Work in Simulator ❌
- **Actual Face ID/Touch ID:** Must use Features menu to simulate
- **Secure Enclave:** Simulator uses software emulation
- **Hardware AES:** Uses software AES (still secure, just slower)
- **Real device performance:** Simulator is faster/slower depending on Mac

### Requires Physical Device 📱
- True Face ID/Touch ID testing
- Secure Enclave validation
- Hardware AES performance
- Production performance testing
- App Store compliance verification

---

## Part 13: Testing on Physical Device

### Setup Physical Device Testing

1. **Connect iPhone/iPad via USB**

2. **Select device in Xcode:**
   - Xcode → Select device dropdown
   - Choose your connected device

3. **Run tests:**
```bash
# Get device UDID
xcrun xctrace list devices

# Run tests on device
xcodebuild test \
  -scheme NeuroGuideApp \
  -destination 'platform=iOS,id=YOUR_DEVICE_UDID'
```

4. **Manual testing:**
   - App lock with real Face ID
   - Performance on actual hardware
   - Battery impact testing
   - Production scenario testing

---

## Summary

**Quick Test Commands:**

```bash
# Run all security unit tests
xcodebuild test -scheme NeuroGuideApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:NeuroGuideTests/EncryptionServiceTests \
  -only-testing:NeuroGuideTests/KeychainServiceTests \
  -only-testing:NeuroGuideTests/SecureStorageTests

# Check encrypted files
cd "$(xcrun simctl get_app_container booted com.neuroguide.NeuroGuideApp data)/Documents/SecureStorage" && ls -la

# Check keychain
security find-generic-password -s "com.neuroguide.storage"

# Enable Face ID in simulator
# Features → Face ID → Enrolled

# Simulate Face ID match
# Features → Face ID → Matching Face
```

**Expected Results:**
- ✅ 79/79 tests pass
- ✅ Files encrypted on disk
- ✅ Master key in keychain
- ✅ Biometric toggle functional
- ✅ App lock works

---

**Last Updated:** 2025-10-22
**Bolt:** 2.2
**Author:** AI-DLC
