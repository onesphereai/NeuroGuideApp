# Location-Based Emergency Resources

## Overview

The app now automatically detects the user's region and shows only relevant emergency resources for their location. This provides a more personalized and helpful experience during crisis situations.

## Supported Regions

### 🇺🇸 United States
- **Emergency Number**: 911
- **Resources**:
  - 988 Suicide & Crisis Lifeline (24/7)
  - Autism Crisis Line (24/7)
  - Crisis Text Line (24/7)
  - NAMI HelpLine (Mon-Fri 10am-10pm ET)
  - Autism Society Helpline (Mon-Fri 9am-5pm ET)

### 🇬🇧 United Kingdom
- **Emergency Number**: 999
- **Resources**:
  - Samaritans (24/7)
  - Mind Infoline (Mon-Fri 9am-6pm)
  - National Autistic Society Helpline (Mon-Fri 9am-5pm)

### 🇨🇦 Canada
- **Emergency Number**: 911
- **Resources**:
  - Crisis Services Canada (24/7)
  - Autism Canada (Mon-Fri 9am-5pm ET)

### 🇦🇺 Australia
- **Emergency Number**: 000
- **Resources**:
  - Lifeline Australia (24/7)
  - Autism Awareness Australia (Mon-Fri 9am-5pm AEST)

## How It Works

### Automatic Region Detection

The app uses the device's locale to automatically determine the user's region:

```swift
func detectRegion() {
    let countryCode = Locale.current.region?.identifier ?? "US"

    switch countryCode {
    case "US": currentRegion = .unitedStates
    case "GB": currentRegion = .unitedKingdom
    case "CA": currentRegion = .canada
    case "AU": currentRegion = .australia
    default: currentRegion = .unitedStates  // Default fallback
    }
}
```

### Resource Filtering

Resources are automatically filtered based on the detected region:

```swift
// Only shows resources for the user's region
var regionalResources: [EmergencyResource] {
    return EmergencyResource.resources(for: currentRegion) + localContacts
}
```

## User Experience

### Visual Indicators

1. **Region Indicator**: Shows which region's resources are being displayed
   ```
   🌍 Showing resources for: United States
   ```

2. **Localized Emergency Numbers**: All emergency call buttons use the correct regional number
   - US/Canada: "Call 911"
   - UK: "Call 999"
   - Australia: "Call 000"

3. **Regional Disclaimers**: The disclaimer message uses the appropriate emergency number for the region

### What Users See

**Before** (All US resources regardless of location):
```
Emergency Resources
├─ Crisis Support (24/7)
│  ├─ 988 Suicide & Crisis Lifeline
│  ├─ Crisis Text Line
│  └─ [US-specific resources]
└─ [Call 911 button]
```

**After** (Region-specific, example UK):
```
Emergency Resources
🌍 Showing resources for: United Kingdom

⚠️ Important: If you're in immediate danger, please call 999

├─ Crisis Support (24/7)
│  └─ Samaritans (116 123)
├─ Mental Health
│  └─ Mind Infoline (0300 123 3393)
└─ Autism Support
   └─ National Autistic Society Helpline (0808 800 4104)

[Call 999 button]
```

## Implementation Details

### Model Changes

**EmergencyResource.swift**:
- Added `Region` enum with support for US, UK, Canada, Australia, International
- Added `region: Region` property to `EmergencyResource`
- Created region-specific resource sets
- Added `resources(for:)` static method for filtering

### Manager Updates

**EmergencyResourcesManager**:
- Added `currentRegion: Region` property
- Added `detectRegion()` method for automatic detection
- Updated `regionalResources` to filter by region
- Updated `addLocalContact()` to tag with current region

### View Updates

**EmergencyResourcesView**:
- Added `RegionIndicatorView` to show current region
- Updated `DisclaimerBanner` to use regional emergency number
- Updated `EmergencyCallButton` to use regional emergency number
- Calls `detectRegion()` on view appear

## Adding New Regions

To add support for a new region:

### 1. Add to Region Enum
```swift
enum Region: String, CaseIterable {
    case newCountry = "XX"  // ISO country code

    var displayName: String {
        switch self {
        case .newCountry: return "New Country"
        }
    }
}
```

### 2. Add Resources
```swift
static let newCountryResource = EmergencyResource(
    id: "xx_resource",
    name: "New Country Crisis Line",
    description: "Crisis support for New Country",
    phoneNumber: "123-456-7890",
    category: .crisis,
    availability: "24/7",
    isNeurodiversityFocused: false,
    region: .newCountry
)
```

### 3. Update Detection
```swift
func detectRegion() {
    let countryCode = Locale.current.region?.identifier ?? "US"

    switch countryCode {
    case "XX": currentRegion = .newCountry
    // ... other cases
    }
}
```

### 4. Update Emergency Numbers
```swift
private var emergencyNumber: String {
    switch region {
    case .newCountry: return "123"
    // ... other cases
    }
}
```

## Privacy & Security

- **No Location Permission Required**: Uses device locale, not GPS
- **No Data Collection**: Region detection is local-only
- **User Privacy**: No personal information or location data is stored or transmitted

## Benefits

### For Users
✅ See only relevant resources for their location
✅ Correct emergency numbers displayed
✅ Reduced confusion during crisis
✅ Faster access to help

### For the App
✅ Better user experience
✅ More professional and trustworthy
✅ Easier to maintain (add new regions)
✅ International-ready

## Testing

To test different regions:

### In Simulator
1. Go to Settings → General → Language & Region
2. Change "Region" to the desired country
3. Relaunch the app
4. Open Emergency Resources
5. Verify correct resources and emergency numbers are shown

### Expected Results by Region

| Region | Emergency # | # of Resources | Key Resources |
|--------|-------------|----------------|---------------|
| US | 911 | 5 | 988, NAMI, Autism Society |
| UK | 999 | 3 | Samaritans, Mind, NAS |
| CA | 911 | 2 | Crisis Services Canada, Autism Canada |
| AU | 000 | 2 | Lifeline, Autism Awareness |

## Future Enhancements

Potential improvements:

1. **Manual Region Selection**: Allow users to override detected region
2. **Multi-Region Support**: Show resources from multiple regions for travelers
3. **More Regions**: Add support for EU countries, Asia, South America
4. **Regional Crisis Protocols**: Different guidance based on regional mental health systems
5. **Language Support**: Show resources in regional languages

---

✅ **Feature Complete**: Location-based emergency resources are now fully implemented and tested!
