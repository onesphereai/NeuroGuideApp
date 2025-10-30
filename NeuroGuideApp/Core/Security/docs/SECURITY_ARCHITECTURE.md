# Security Architecture

**Bolt 2.2 - Data Encryption & Security**
**NeuroGuide iOS Application**

## Overview

This document describes the comprehensive security architecture implemented in NeuroGuide to protect sensitive family data, including encryption at rest, secure key management, and biometric authentication.

---

## Table of Contents

1. [Security Principles](#security-principles)
2. [Architecture Overview](#architecture-overview)
3. [Encryption Implementation](#encryption-implementation)
4. [Key Management](#key-management)
5. [Biometric Authentication](#biometric-authentication)
6. [Data Storage](#data-storage)
7. [Threat Model](#threat-model)
8. [Security Best Practices](#security-best-practices)

---

## Security Principles

### Core Commitments

1. **Defense in Depth:** Multiple layers of security (encryption, keychain, file protection, biometric)
2. **Privacy by Design:** Security built-in from the start, not added later
3. **Zero Knowledge:** App cannot access data without user authentication
4. **Fail Secure:** System fails closed if security cannot be guaranteed
5. **Minimal Trust:** Don't trust any component unnecessarily

### Compliance Targets

- **HIPAA** - Health Insurance Portability and Accountability Act (future)
- **COPPA** - Children's Online Privacy Protection Act
- **GDPR** - General Data Protection Regulation (if EU users)
- **CCPA** - California Consumer Privacy Act (if CA users)

---

## Architecture Overview

### Security Layers

```
┌─────────────────────────────────────────┐
│         Application Layer               │
│   (User Interface, Business Logic)      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      SecureStorageService               │
│  - Automatic Encryption/Decryption      │
│  - File Management                      │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
┌─────────────┐ ┌──────────────┐
│ Encryption  │ │   Keychain   │
│  Service    │ │   Service    │
│ AES-256-GCM │ │ (Master Key) │
└─────────────┘ └──────────────┘
        │             │
        └──────┬──────┘
               ▼
┌─────────────────────────────────────────┐
│         iOS Security Framework          │
│  - Secure Enclave                       │
│  - Hardware AES                         │
│  - LocalAuthentication (Face ID)        │
└─────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Purpose | Security Feature |
|-----------|---------|------------------|
| **EncryptionService** | Encrypt/decrypt data | AES-256-GCM |
| **KeychainService** | Store secrets | Secure Enclave protection |
| **SecureStorageService** | Manage encrypted files | Automatic encryption |
| **BiometricAuthService** | User authentication | Face ID / Touch ID |
| **AppLockManager** | App-level security | Biometric app lock |

---

## Encryption Implementation

### Algorithm: AES-256-GCM

**Advanced Encryption Standard with Galois/Counter Mode**

**Why AES-256-GCM?**
- **NIST Approved:** Recommended by National Institute of Standards and Technology
- **Authenticated Encryption:** Provides both confidentiality and integrity
- **Hardware Accelerated:** Apple Silicon has dedicated AES instructions
- **Performance:** Fast encryption/decryption
- **Security:** 256-bit keys provide exceptional security margin

**Specifications:**
- **Algorithm:** AES-256-GCM
- **Key Size:** 256 bits (32 bytes)
- **Nonce Size:** 96 bits (12 bytes) - recommended for GCM
- **Tag Length:** 128 bits (16 bytes) - authentication tag
- **Mode:** GCM (Galois/Counter Mode)

**Data Format:**
```
[Nonce (12 bytes)][Ciphertext (variable)][Authentication Tag (16 bytes)]
```

**Implementation:**
```swift
import CryptoKit

let key = SymmetricKey(size: .bits256)
let sealedBox = try AES.GCM.seal(data, using: key)
let combined = sealedBox.combined // Contains nonce + ciphertext + tag
```

### Encryption Flow

**Save Operation:**
```
User Data
    ↓
JSON Encoding
    ↓
AES-256-GCM Encryption (with master key)
    ↓
Write to File (with file protection)
    ↓
Encrypted File on Disk
```

**Load Operation:**
```
Encrypted File on Disk
    ↓
Read File
    ↓
AES-256-GCM Decryption (with master key)
    ↓
JSON Decoding
    ↓
User Data
```

### Security Properties

1. **Confidentiality:** Data encrypted, cannot be read without key
2. **Integrity:** Authentication tag ensures data hasn't been tampered with
3. **Authenticity:** Only holder of master key can create valid ciphertext
4. **Non-Malleability:** Cannot modify ciphertext without detection

---

## Key Management

### Master Key Architecture

**Hierarchical Key Structure:**
```
Master Key (256-bit)
    ├─ Stored in iOS Keychain
    ├─ Protected by Secure Enclave
    ├─ Can be bound to biometrics
    └─ Used to encrypt all data

Per-File Encryption
    └─ Same master key encrypts all files
    └─ Each encryption uses unique nonce (ensures different ciphertext)
```

### Master Key Lifecycle

**Generation:**
```swift
// On first launch
let masterKey = try encryptionService.generateKey() // 256-bit random

// Store in keychain
try keychainService.save(
    data: masterKey,
    forKey: "com.neuroguide.storage.masterKey",
    accessible: .afterFirstUnlockThisDeviceOnly
)
```

**Retrieval:**
```swift
// On subsequent uses
let masterKey = try keychainService.load(
    key: "com.neuroguide.storage.masterKey"
)
```

**Deletion:**
```swift
// On app uninstall (automatic via iOS sandbox)
// On explicit reset
try keychainService.delete(key: "com.neuroguide.storage.masterKey")
```

### Keychain Configuration

**Access Control:**
- **Accessibility:** `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- **Why:** Available after first unlock, never syncs to iCloud
- **Biometric Binding:** Optional (can require Face ID to access key)

**Service Isolation:**
- Each service has unique identifier (prevents cross-contamination)
- Example: `com.neuroguide.storage`, `com.neuroguide.app`

**No iCloud Sync:**
- Master key NEVER syncs to iCloud
- Ensures data stays on device even if user enables iCloud Keychain

---

## Biometric Authentication

### Supported Methods

1. **Face ID** - iPhone X and newer
2. **Touch ID** - iPhone 8 and older, iPads
3. **Passcode Fallback** - If biometric fails

### Implementation

```swift
import LocalAuthentication

let context = LAContext()
let reason = "Unlock NeuroGuide to continue"

let success = try await context.evaluatePolicy(
    .deviceOwnerAuthenticationWithBiometrics,
    localizedReason: reason
)
```

### App Lock Flow

**Lock Trigger:**
1. App enters background
2. User stays in background > 30 seconds
3. App returns to foreground
4. **Action:** Lock app, show lock screen

**Unlock Flow:**
1. Show lock screen (blurred background)
2. Prompt for biometric authentication
3. If success → unlock app
4. If fail → retry or use passcode

**Timeout Configuration:**
```swift
private let lockTimeoutSeconds: TimeInterval = 30 // Configurable
```

### Security Considerations

**Privacy:**
- Biometric data never leaves Secure Enclave
- App only receives success/failure (never biometric data itself)

**Availability:**
- Graceful degradation if biometric not available
- User can disable app lock (optional feature)

**Lockout Protection:**
- iOS handles lockout after failed attempts
- Fallback to device passcode

---

## Data Storage

### File System Layout

```
/var/mobile/Containers/Data/Application/{UUID}/
├── Documents/
│   └── SecureStorage/
│       ├── app.settings.enc
│       ├── privacy.settings.enc
│       ├── child.profile.{id}.enc
│       └── session.data.{id}.enc
├── Library/
│   ├── Caches/           # Temporary data (not encrypted)
│   └── Application Support/
└── tmp/                  # Ephemeral data
```

### File Protection Attributes

**iOS Data Protection:**
```swift
let attributes = [
    FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
]
```

**Protection Classes:**

| Class | When Available | Use Case |
|-------|----------------|----------|
| **Complete** | Only when unlocked | Most secure (not used - too restrictive) |
| **CompleteUnlessOpen** | Remains open if opened before lock | Not used |
| **CompleteUntilFirstUserAuthentication** | After first unlock | **USED** - Balance of security/usability |
| **None** | Always | Not used for sensitive data |

**Why CompleteUntilFirstUserAuthentication?**
- Available after device boots and user unlocks once
- Allows background operations (notifications, etc.)
- Protects against physical theft before first unlock
- Standard for most apps

### Backup Exclusion

**Master Key:**
- Automatically excluded from iCloud backup (keychain configuration)

**Encrypted Files:**
- Can be backed up to iCloud (already encrypted)
- User controls via iOS settings

---

## Threat Model

### Threats Addressed

#### 1. Physical Device Access (Unlocked Device)
**Threat:** Attacker has physical access to unlocked device

**Mitigation:**
- ✅ Biometric app lock (optional)
- ✅ Auto-lock after 30s in background
- ✅ Encrypted storage (even if app is running)

**Risk:** Medium → Low

---

#### 2. Physical Device Theft (Locked Device)
**Threat:** Attacker steals locked device

**Mitigation:**
- ✅ Master key in Keychain (Secure Enclave protected)
- ✅ File protection (CompleteUntilFirstUserAuthentication)
- ✅ AES-256-GCM encryption
- ✅ No key recovery mechanism (attacker cannot extract key)

**Risk:** High → Very Low

---

#### 3. Backup Extraction
**Threat:** Attacker extracts data from iTunes/iCloud backup

**Mitigation:**
- ✅ Master key never backed up (keychain configuration)
- ✅ Files are encrypted (even in backup)
- ⚠️ Backup password protects backup (user responsibility)

**Risk:** Medium → Low (if user has backup password)

---

#### 4. Jailbroken Device
**Threat:** User jailbreaks device, bypasses security

**Mitigation:**
- ⚠️ Limited mitigation available (cannot prevent root access)
- ✅ Keychain still provides some protection
- ⚠️ User has explicitly weakened device security

**Risk:** Cannot mitigate (user choice)

**Note:** App does not block jailbroken devices (inclusive design)

---

#### 5. Memory Dump Attack
**Threat:** Attacker dumps app memory while running

**Mitigation:**
- ⚠️ Master key in memory while app running (necessary)
- ✅ Key cleared on app termination
- ✅ Background privacy screen (hides UI from task switcher)

**Risk:** Medium (requires sophisticated attack)

---

#### 6. Side-Channel Attacks
**Threat:** Timing attacks, power analysis, etc.

**Mitigation:**
- ✅ Hardware AES (constant-time)
- ✅ CryptoKit uses secure implementations
- ✅ No custom crypto (avoid implementation bugs)

**Risk:** Very Low (requires physical proximity + equipment)

---

### Threats NOT Addressed

#### 1. Malware on Device
**Not Mitigated:** Malware running with app permissions can access decrypted data

**Reason:** iOS sandboxing provides baseline protection, but malware with same permissions can intercept

#### 2. Compromised iOS
**Not Mitigated:** If iOS itself is compromised, all bets are off

**Reason:** Must trust operating system

#### 3. User Shares Passcode
**Not Mitigated:** If user willingly shares device passcode with attacker

**Reason:** Cannot protect against social engineering

---

## Security Best Practices

### For Developers

1. **Never Log Sensitive Data:**
   ```swift
   // ❌ BAD
   print("Decrypted data: \(data)")

   // ✅ GOOD
   print("Decryption succeeded, \(data.count) bytes")
   ```

2. **Zero Sensitive Variables:**
   ```swift
   // ✅ GOOD
   var sensitiveData = Data()
   defer { sensitiveData.resetBytes(in: 0..<sensitiveData.count) }
   ```

3. **Use Keychain for All Secrets:**
   ```swift
   // ❌ BAD
   UserDefaults.standard.set(apiKey, forKey: "apiKey")

   // ✅ GOOD
   try keychainService.save(data: apiKey, forKey: "apiKey")
   ```

4. **Always Use Encrypted Storage:**
   ```swift
   // ❌ BAD
   try JSONEncoder().encode(profile).write(to: fileURL)

   // ✅ GOOD
   try await secureStorage.save(profile, forKey: "profile")
   ```

### For Users

1. **Enable Device Passcode:** Required for data protection
2. **Use Strong Passcode:** 6+ digits or alphanumeric
3. **Enable Face ID/Touch ID:** Adds extra layer of security
4. **Enable App Lock:** Optional biometric app lock in settings
5. **Keep iOS Updated:** Security patches

---

## Security Audit Checklist

- [x] All sensitive data encrypted at rest
- [x] Master key stored in Keychain
- [x] No plaintext sensitive data on disk
- [x] AES-256-GCM used (not weaker algorithms)
- [x] Unique nonce per encryption
- [x] Authentication tags verified on decryption
- [x] No custom crypto implementations
- [x] Keychain accessibility configured correctly
- [x] File protection attributes set
- [x] No secrets in code or version control
- [x] Biometric authentication implemented
- [x] App lock functional
- [x] Background privacy screen implemented
- [x] No network transmission of sensitive data
- [x] Comprehensive error handling
- [x] Unit tests for encryption round-trip
- [x] Unit tests for keychain operations
- [x] Integration tests for secure storage

---

## References

- [Apple CryptoKit Documentation](https://developer.apple.com/documentation/cryptokit)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [NIST AES Recommendation](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)

---

**Last Updated:** 2025-10-22
**Bolt Version:** 2.2
**Author:** AI-DLC
