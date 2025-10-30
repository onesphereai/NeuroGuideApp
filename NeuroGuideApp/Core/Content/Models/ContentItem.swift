//
//  ContentItem.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 4 - Content Library & Management
//

import Foundation

/// A single content item in the library
/// Contains curated, neurodiversity-affirming guidance
struct ContentItem: Identifiable, Equatable {
    // MARK: - Identity

    let id: UUID

    // MARK: - Content

    var title: String
    var body: String
    var summary: String?  // Short summary for list views

    // MARK: - Organization

    var category: ContentCategory
    var subcategory: String?
    var tags: [String]

    // MARK: - Attribution

    var sourceType: SourceType
    var sourceAttribution: String
    var sourceLinks: [URL]

    // MARK: - Context

    var ageRange: ClosedRange<Int>  // 2-8 years
    var arousalBands: [ArousalBand]?  // Which arousal states this helps with
    var emotionStates: [String]?  // Which emotions this addresses
    var sensoryProfiles: [String]?  // Seeking/Avoiding tags

    // MARK: - Metadata

    var version: Int
    var lastUpdated: Date
    var isDeprecated: Bool
    var reviewStatus: ReviewStatus

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        summary: String? = nil,
        category: ContentCategory,
        subcategory: String? = nil,
        tags: [String] = [],
        sourceType: SourceType,
        sourceAttribution: String,
        sourceLinks: [URL] = [],
        ageRange: ClosedRange<Int> = 2...8,
        arousalBands: [ArousalBand]? = nil,
        emotionStates: [String]? = nil,
        sensoryProfiles: [String]? = nil,
        version: Int = 1,
        lastUpdated: Date = Date(),
        isDeprecated: Bool = false,
        reviewStatus: ReviewStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.summary = summary
        self.category = category
        self.subcategory = subcategory
        self.tags = tags
        self.sourceType = sourceType
        self.sourceAttribution = sourceAttribution
        self.sourceLinks = sourceLinks
        self.ageRange = ageRange
        self.arousalBands = arousalBands
        self.emotionStates = emotionStates
        self.sensoryProfiles = sensoryProfiles
        self.version = version
        self.lastUpdated = lastUpdated
        self.isDeprecated = isDeprecated
        self.reviewStatus = reviewStatus
    }
}

// MARK: - Content Category

/// Primary categories for content organization
enum ContentCategory: String, Codable, CaseIterable {
    case arousalRegulation = "Arousal Regulation"
    case sensorySupport = "Sensory Support"
    case communication = "Communication"
    case dailyRoutines = "Daily Routines"
    case parentSelfCare = "Parent Self-Care"

    var icon: String {
        switch self {
        case .arousalRegulation:
            return "waveform.path.ecg"
        case .sensorySupport:
            return "hand.raised.fill"
        case .communication:
            return "bubble.left.and.bubble.right.fill"
        case .dailyRoutines:
            return "calendar"
        case .parentSelfCare:
            return "heart.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .arousalRegulation:
            return "Strategies for managing arousal levels and emotional regulation"
        case .sensorySupport:
            return "Sensory accommodations and supports"
        case .communication:
            return "Communication strategies and supports"
        case .dailyRoutines:
            return "Daily living and routine support"
        case .parentSelfCare:
            return "Self-care and co-regulation for caregivers"
        }
    }
}

// MARK: - Source Type

/// Type of source for content attribution
enum SourceType: String, Codable, CaseIterable {
    case peerReviewedResearch = "Peer-Reviewed Research"
    case clinicalGuidelines = "Clinical Guidelines"
    case autisticCommunityInput = "Autistic Community Input"
    case parentReportedStrategies = "Parent-Reported Strategies"

    var badge: String {
        switch self {
        case .peerReviewedResearch:
            return "Research-Based"
        case .clinicalGuidelines:
            return "Clinical Guidelines"
        case .autisticCommunityInput:
            return "Community Wisdom"
        case .parentReportedStrategies:
            return "Parent-Shared"
        }
    }

    var color: String {
        switch self {
        case .peerReviewedResearch:
            return "blue"
        case .clinicalGuidelines:
            return "purple"
        case .autisticCommunityInput:
            return "green"
        case .parentReportedStrategies:
            return "orange"
        }
    }
}

// MARK: - Review Status

/// Status of content in advisor review workflow
enum ReviewStatus: String, Codable {
    case pending = "Pending Review"
    case approved = "Approved"
    case requestedChanges = "Changes Requested"
    case rejected = "Rejected"
}

// MARK: - Arousal Band Extension

extension ArousalBand {
    /// Tags associated with this arousal band for content filtering
    var contentTags: [String] {
        switch self {
        case .shutdown:
            return ["low-arousal", "alerting", "engagement"]
        case .green:
            return ["calm", "regulated", "maintenance"]
        case .yellow:
            return ["elevated", "early-warning", "prevention"]
        case .orange:
            return ["high-arousal", "de-escalation", "immediate"]
        case .red:
            return ["crisis", "safety", "emergency"]
        }
    }
}

// MARK: - Helper Methods

extension ContentItem {
    /// Check if this content is appropriate for a given age
    func isAppropriateForAge(_ age: Int) -> Bool {
        return ageRange.contains(age)
    }

    /// Check if this content matches any of the provided tags
    func matchesTags(_ searchTags: [String]) -> Bool {
        let lowercaseTags = tags.map { $0.lowercased() }
        let lowercaseSearchTags = searchTags.map { $0.lowercased() }
        return !Set(lowercaseTags).isDisjoint(with: Set(lowercaseSearchTags))
    }

    /// Check if this content is relevant for an arousal band
    func isRelevantForArousalBand(_ band: ArousalBand) -> Bool {
        guard let arousalBands = arousalBands else { return true }
        return arousalBands.contains(band)
    }

    /// Get a display-friendly age range string
    var ageRangeString: String {
        if ageRange.lowerBound == ageRange.upperBound {
            return "\(ageRange.lowerBound) years"
        } else {
            return "\(ageRange.lowerBound)-\(ageRange.upperBound) years"
        }
    }
}

// MARK: - Codable Implementation

extension ContentItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, body, summary, category, subcategory, tags
        case sourceType, sourceAttribution, sourceLinks
        case ageRange, arousalBands, emotionStates, sensoryProfiles
        case version, lastUpdated, isDeprecated, reviewStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        category = try container.decode(ContentCategory.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        tags = try container.decode([String].self, forKey: .tags)
        sourceType = try container.decode(SourceType.self, forKey: .sourceType)
        sourceAttribution = try container.decode(String.self, forKey: .sourceAttribution)
        sourceLinks = try container.decode([URL].self, forKey: .sourceLinks)

        // Decode age range from dictionary
        let rangeDict = try container.decode([String: Int].self, forKey: .ageRange)
        let lower = rangeDict["lowerBound"] ?? 2
        let upper = rangeDict["upperBound"] ?? 8
        ageRange = lower...upper

        arousalBands = try container.decodeIfPresent([ArousalBand].self, forKey: .arousalBands)
        emotionStates = try container.decodeIfPresent([String].self, forKey: .emotionStates)
        sensoryProfiles = try container.decodeIfPresent([String].self, forKey: .sensoryProfiles)
        version = try container.decode(Int.self, forKey: .version)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        isDeprecated = try container.decode(Bool.self, forKey: .isDeprecated)
        reviewStatus = try container.decode(ReviewStatus.self, forKey: .reviewStatus)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(subcategory, forKey: .subcategory)
        try container.encode(tags, forKey: .tags)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(sourceAttribution, forKey: .sourceAttribution)
        try container.encode(sourceLinks, forKey: .sourceLinks)

        // Encode age range as dictionary
        let rangeDict = ["lowerBound": ageRange.lowerBound, "upperBound": ageRange.upperBound]
        try container.encode(rangeDict, forKey: .ageRange)

        try container.encodeIfPresent(arousalBands, forKey: .arousalBands)
        try container.encodeIfPresent(emotionStates, forKey: .emotionStates)
        try container.encodeIfPresent(sensoryProfiles, forKey: .sensoryProfiles)
        try container.encode(version, forKey: .version)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(isDeprecated, forKey: .isDeprecated)
        try container.encode(reviewStatus, forKey: .reviewStatus)
    }
}
