# Instagram-Style Profile Switcher

## Overview

Implemented an Instagram-style profile switcher that displays all child profiles at the top of the home screen. Users can quickly switch between profiles by tapping on circular profile avatars, similar to Instagram stories.

## Features

### Visual Design

1. **Profile Avatars**:
   - Circular avatar with colored background (auto-generated from profile ID)
   - Initials displayed (first letter of first and last name, or first 2 letters)
   - Gradient ring around active profile (blue-purple-pink gradient)
   - Profile name label below avatar

2. **Active Profile Indicator**:
   - Animated gradient border (like Instagram stories)
   - Bold name text
   - Accessibility traits for screen reader support

3. **Add Profile Button**:
   - Dashed circle with "+" icon
   - "Add" label
   - Opens profile creation modal

### User Experience

**Horizontal Scrolling**:
- Profiles displayed in a horizontal scroll view
- No scroll indicators for clean UI
- Smooth scrolling between profiles

**Profile Switching**:
- Tap any profile avatar to instantly switch
- Active profile updates immediately
- VoiceOver announcement confirms switch

**Multi-Profile Detection**:
- Switcher only appears when 2+ profiles exist
- For single profile users, switcher is hidden
- Automatically shows/hides based on profile count

## Implementation Details

### New Components

**ProfileSwitcherView.swift**:
```swift
struct ProfileSwitcherView: View
```
- Main switcher component
- Displays all profiles horizontally
- Handles profile selection and "add" action

**ProfileAvatarButton**:
```swift
struct ProfileAvatarButton: View
```
- Individual profile avatar with ring indicator
- Color generation based on profile ID hash
- Initials extraction from name

**AddProfileButton**:
```swift
struct AddProfileButton: View
```
- "Add new profile" button
- Dashed circle design
- Opens profile creation modal

### Updated Components

**HomeView.swift**:
- Added ProfileSwitcherView at the top
- Removed old "Switch" button from toolbar
- Switcher positioned above ScrollView
- Subtle shadow for visual separation

**HomeViewModel.swift**:
- Added `allProfiles: [ChildProfile]` property
- Added `shouldShowProfileSwitcher: Bool` property
- Updated `loadProfile()` to load all profiles
- Added `selectProfile(_ profile:)` method
- Added `createNewProfile()` method

**AppCoordinator.swift**:
- Added `navigateToProfileCreation()` method
- Opens profile creation as modal

## Color Palette

Avatars use consistent colors based on profile ID:
- Blue
- Purple
- Pink
- Orange
- Green
- Indigo
- Teal

Colors are deterministic (same profile always gets same color).

## Accessibility

### VoiceOver Support

1. **Profile Avatars**:
   - Label: "[Name]'s profile"
   - Hint: "Double tap to switch to this profile" (inactive)
   - Hint: "Currently selected" (active)
   - Trait: `.isSelected` for active profile

2. **Add Button**:
   - Label: "Add new profile"
   - Hint: "Double tap to create a new child profile"

3. **Profile Switch Announcement**:
   - Announces: "Switched to [Name]'s profile"

### Haptic Feedback

- Button tap haptic when selecting profile
- Button tap haptic when tapping "Add"

## Layout

```
┌────────────────────────────────────────────┐
│ ○ ○ ◎ ○ ⊕                                  │ ← Profile Switcher
│ Emma Liam Sophia Alex Add                  │
├────────────────────────────────────────────┤
│                                             │
│ Good Morning                                │
│ How can we support you today?              │
│                                             │
│ [Sophia's Profile Summary]                  │
│                                             │
│ ┌─────────┐ ┌─────────┐                   │
│ │  Live   │ │ Emotion │                   │
│ │  Coach  │ │  Check  │                   │
│ └─────────┘ └─────────┘                   │
│ ...                                         │
└────────────────────────────────────────────┘

Legend:
○ = Profile avatar (inactive)
◎ = Profile avatar (active, with gradient ring)
⊕ = Add profile button
```

## User Flow

### Switching Profiles

1. User opens home screen
2. Sees all profiles at the top (if 2+ profiles exist)
3. Active profile has gradient ring
4. Taps different profile avatar
5. Profile instantly switches
6. Profile summary and features update
7. VoiceOver announces switch

### Adding New Profile

1. User taps "Add" button (⊕)
2. Profile creation modal opens
3. User completes profile creation
4. Returns to home screen
5. New profile appears in switcher
6. User can immediately switch to it

## Benefits

### For Users

✅ **Quick Switching**: Instant profile changes without navigation
✅ **Visual Clarity**: See all profiles at once
✅ **Familiar Pattern**: Instagram-style interaction
✅ **Easy Discovery**: "Add" button always visible
✅ **Accessible**: Full VoiceOver support

### For the App

✅ **Clean UI**: Removed toolbar button clutter
✅ **Modern Design**: Instagram-inspired aesthetic
✅ **Scalable**: Works with 2-10+ profiles
✅ **Performance**: Lazy loading, efficient rendering
✅ **Maintainable**: Reusable components

## Testing

### Manual Testing

1. **Single Profile**:
   - Verify switcher is hidden
   - Verify profile summary still appears

2. **Multiple Profiles** (2-5):
   - Verify all profiles appear
   - Verify active profile has gradient ring
   - Verify tapping switches profile instantly
   - Verify names truncate properly

3. **Many Profiles** (6+):
   - Verify horizontal scrolling works
   - Verify all profiles accessible
   - Verify smooth scrolling

4. **Add Profile**:
   - Verify "Add" button opens modal
   - Verify new profile appears in switcher
   - Verify can switch to new profile

### Accessibility Testing

1. **VoiceOver**:
   - Enable VoiceOver
   - Swipe through profiles
   - Verify correct labels and hints
   - Verify switch announcement
   - Verify active profile trait

2. **Dynamic Type**:
   - Increase text size to max
   - Verify names still visible
   - Verify avatars maintain size

## Future Enhancements

Potential improvements:

1. **Profile Photos**: Support actual photos instead of initials
2. **Last Active Indicator**: Show timestamp of last use
3. **Reordering**: Long-press to rearrange profiles
4. **Profile Search**: Search bar for many profiles (10+)
5. **Profile Colors**: Allow users to customize avatar colors
6. **Animated Transitions**: Smooth profile switch animations
7. **Badge Indicators**: Show unread notifications per profile

---

✅ **Feature Complete**: Instagram-style profile switcher is fully implemented and tested!
