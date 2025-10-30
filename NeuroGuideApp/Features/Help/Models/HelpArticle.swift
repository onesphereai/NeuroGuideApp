//
//  HelpArticle.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System
//

import Foundation

/// Represents a help article or FAQ
struct HelpArticle: Identifiable, Hashable {
    let id: String
    let title: String
    let content: String
    let category: HelpCategory
    let keywords: [String]

    enum HelpCategory: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case sessions = "Using Sessions"
        case childProfiles = "Child Profiles"
        case accessibility = "Accessibility"
        case privacy = "Privacy & Data"
        case troubleshooting = "Troubleshooting"
    }
}

// MARK: - Default Help Articles

extension HelpArticle {
    static let defaultArticles: [HelpArticle] = [
        // Getting Started
        HelpArticle(
            id: "welcome",
            title: "Welcome to attune",
            content: """
            Attune is designed to help you support your autistic child through guided check-in sessions.

            **Key Features:**
            • Guided check-in sessions with your child
            • Track emotional patterns over time
            • Discover coping strategies that work
            • Build understanding through neurodiversity-affirming content

            **Getting Started:**
            1. Create a profile for your child
            2. Start your first check-in session
            3. Review insights and patterns
            4. Explore recommended strategies

            Everything stays on your device unless you choose to sync.
            """,
            category: .gettingStarted,
            keywords: ["welcome", "intro", "introduction", "start", "begin"]
        ),

        HelpArticle(
            id: "first-session",
            title: "Starting Your First Session",
            content: """
            Your first check-in session is a gentle conversation with your child.

            **Before You Start:**
            • Choose a calm, quiet moment
            • Let your child know this is about understanding them better
            • Have a comfortable space with minimal distractions

            **During the Session:**
            • Follow the guided prompts
            • There are no wrong answers
            • You can pause or skip questions anytime
            • Sessions typically take 5-10 minutes

            **After the Session:**
            • Review the summary together if your child wants
            • You can add notes about what you observed
            • Patterns emerge after a few sessions

            Remember: This is about understanding, not fixing.
            """,
            category: .gettingStarted,
            keywords: ["first", "session", "start", "begin", "checkin"]
        ),

        // Sessions
        HelpArticle(
            id: "session-guide",
            title: "How Check-In Sessions Work",
            content: """
            Sessions are guided conversations to understand your child's experience.

            **Session Structure:**
            1. **Opening** - Set the tone and get comfortable
            2. **Check-In** - Explore current feelings and needs
            3. **Reflection** - Identify patterns and strategies
            4. **Closing** - Summarize and plan next steps

            **Tips for Success:**
            • Be present and non-judgmental
            • Follow your child's lead
            • Validate their experiences
            • Celebrate small discoveries

            **Flexibility:**
            • Skip questions that don't feel right
            • Pause anytime to take a break
            • End early if needed
            • Sessions adapt to your child's responses
            """,
            category: .sessions,
            keywords: ["session", "checkin", "how", "work", "guide"]
        ),

        HelpArticle(
            id: "session-tips",
            title: "Tips for Effective Sessions",
            content: """
            Make check-in sessions work better for your family.

            **Timing:**
            • Pick consistent times when possible
            • Avoid right after school or stressful events
            • Morning or evening often work well
            • Don't force it if timing feels wrong

            **Environment:**
            • Quiet space with minimal distractions
            • Comfortable seating
            • Good lighting (not too bright)
            • Consider sensory preferences

            **Approach:**
            • Start with curiosity, not concern
            • Listen more than you talk
            • Validate all feelings
            • Notice nonverbal cues
            • Celebrate willingness to share

            **Frequency:**
            • Start with once or twice weekly
            • Adjust based on what works
            • More frequent during transitions
            • Less pressure = better engagement
            """,
            category: .sessions,
            keywords: ["tips", "session", "effective", "better", "improve"]
        ),

        // Child Profiles
        HelpArticle(
            id: "child-profiles",
            title: "Managing Child Profiles",
            content: """
            Create and manage profiles for each child you support.

            **Creating a Profile:**
            1. Go to Profile Management
            2. Tap "Add New Profile"
            3. Enter your child's name and details
            4. Customize sensory and communication preferences

            **What's Stored:**
            • Basic information (name, age, pronouns)
            • Session history and patterns
            • Preferred coping strategies
            • Communication preferences
            • Sensory preferences

            **Privacy:**
            • All data stays on your device by default
            • No personal information shared
            • Each profile is separate and secure
            • You can delete profiles anytime

            **Multiple Profiles:**
            • Create one profile per child
            • Switch between profiles easily
            • Each has independent session history
            """,
            category: .childProfiles,
            keywords: ["profile", "child", "create", "manage", "multiple"]
        ),

        // Accessibility
        HelpArticle(
            id: "voiceover",
            title: "Using attune with VoiceOver",
            content: """
            Attune is fully accessible with VoiceOver.

            **Navigation:**
            • All screens have clear labels
            • Buttons announce their purpose
            • Forms provide helpful hints
            • Modal dialogs are clearly announced

            **During Sessions:**
            • Questions are read in full
            • Response options are clearly labeled
            • Progress is announced
            • You can navigate answers easily

            **Gestures:**
            • Standard VoiceOver gestures work throughout
            • Swipe right/left to move between elements
            • Double-tap to activate
            • Three-finger swipe for page navigation

            **Tips:**
            • Adjust speaking rate in iOS Settings
            • Use headphones for privacy
            • Rotor provides quick navigation
            """,
            category: .accessibility,
            keywords: ["voiceover", "accessibility", "blind", "screen reader"]
        ),

        HelpArticle(
            id: "accessibility-features",
            title: "Accessibility Features",
            content: """
            NeuroGuide supports diverse accessibility needs.

            **Visual:**
            • Dynamic Type for text sizing
            • High contrast mode
            • Dark mode support
            • Clear visual hierarchy
            • Sufficient color contrast

            **Motor:**
            • Large tap targets
            • No time-based interactions
            • Simple gestures
            • Voice Control compatible
            • Switch Control supported

            **Cognitive:**
            • Clear, simple language
            • Consistent navigation
            • Minimal distractions
            • Progress indicators
            • Save and resume anytime

            **Sensory:**
            • Optional haptic feedback
            • Reduce motion support
            • Calm color palette
            • No sudden sounds
            • No flashing content

            Configure these in Settings > Accessibility.
            """,
            category: .accessibility,
            keywords: ["accessibility", "features", "support", "adapt"]
        ),

        // Privacy & Data
        HelpArticle(
            id: "data-privacy",
            title: "How Your Data is Protected",
            content: """
            Your privacy is fundamental to NeuroGuide.

            **On-Device by Default:**
            • All data stored locally on your device
            • Nothing sent to servers by default
            • No tracking or analytics
            • No third-party access

            **What We Store:**
            • Child profiles (names, preferences)
            • Session summaries and responses
            • Your notes and observations
            • App settings and preferences

            **What We Don't Store:**
            • No medical information
            • No identifying information beyond names
            • No location data
            • No contacts or photos

            **Your Control:**
            • Export data anytime
            • Delete individual sessions
            • Delete entire profiles
            • Set data retention periods
            • Enable auto-delete for old sessions

            **Optional Cloud Sync:**
            • End-to-end encrypted
            • Only if you enable it
            • You can disable anytime
            """,
            category: .privacy,
            keywords: ["privacy", "data", "security", "protection", "safe"]
        ),

        HelpArticle(
            id: "data-retention",
            title: "Managing Your Data",
            content: """
            Control how long session data is kept.

            **Data Retention Settings:**
            Go to Settings > Privacy & Data to configure:
            • Keep history for 30, 60, 90, 180, or 365 days
            • Or keep forever
            • Enable auto-delete for old sessions

            **Manual Deletion:**
            • Delete individual sessions from History
            • Delete entire profiles from Profile Management
            • Delete all data from Settings

            **What Happens When Deleted:**
            • Data is permanently removed
            • Cannot be recovered
            • Does not affect other profiles
            • App continues to work normally

            **Export Before Deleting:**
            • Export data to save externally
            • Share with professionals if needed
            • Keep backups of important insights

            **Recommendations:**
            • Keep at least 90 days to spot patterns
            • Export before major deletions
            • Review privacy settings periodically
            """,
            category: .privacy,
            keywords: ["retention", "delete", "data", "manage", "remove"]
        ),

        // Troubleshooting
        HelpArticle(
            id: "app-not-responding",
            title: "App Not Responding",
            content: """
            If NeuroGuide freezes or becomes unresponsive:

            **Quick Fixes:**
            1. Force close the app
            2. Wait 10 seconds
            3. Reopen NeuroGuide
            4. Your data is automatically saved

            **If Problems Persist:**
            1. Check for app updates in App Store
            2. Restart your iPhone/iPad
            3. Ensure iOS is up to date
            4. Check available storage (Settings > General > Storage)

            **During a Session:**
            • Sessions auto-save every 30 seconds
            • You won't lose progress
            • Resume from where you left off

            **Still Having Issues?**
            Contact support through Settings > Help & Support > Contact Us

            Include:
            • iOS version
            • App version (in Settings)
            • What you were doing when it happened
            • Any error messages shown
            """,
            category: .troubleshooting,
            keywords: ["freeze", "crash", "hang", "stuck", "not responding"]
        ),

        HelpArticle(
            id: "session-not-saving",
            title: "Sessions Not Saving",
            content: """
            If your sessions aren't being saved properly:

            **Check Storage:**
            1. Go to iOS Settings > General > Storage
            2. Ensure you have at least 100MB free
            3. Delete unused apps or photos if needed

            **Check Permissions:**
            • NeuroGuide doesn't require special permissions
            • But iOS needs storage space to function

            **Force a Save:**
            1. Complete the session fully
            2. Wait for the summary screen
            3. Tap "Done" or "Save Session"
            4. Don't force-close during saving

            **Recovery:**
            • Check History tab - sessions may be there
            • Look for auto-saved drafts
            • Recent sessions should appear within minutes

            **Prevention:**
            • Complete sessions when possible
            • Don't switch apps during saving
            • Keep iOS updated
            • Maintain adequate storage

            If issues continue, contact support.
            """,
            category: .troubleshooting,
            keywords: ["save", "saving", "lost", "missing", "session"]
        )
    ]
}
