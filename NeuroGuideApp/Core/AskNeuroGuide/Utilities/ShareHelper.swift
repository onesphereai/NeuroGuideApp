//
//  ShareHelper.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Helper for formatting and sharing content from Ask NeuroGuide
struct ShareHelper {

    // MARK: - Share Formats

    /// Format answer as plain text
    static func formatAsText(answer: ContentAnswer, question: String? = nil) -> String {
        var text = ""

        // Question (if provided)
        if let question = question {
            text += "Q: \(question)\n\n"
        }

        // Answer content
        text += "\(answer.content)\n\n"

        // Source attribution
        text += "Source: \(answer.source.title)"
        if let section = answer.source.section {
            text += " - \(section)"
        }
        text += "\n"

        // Author
        if let author = answer.source.author {
            text += "By: \(author)\n"
        }

        // Credibility level
        text += "Credibility: \(answer.source.credibilityLevel.displayName)\n"

        // Strategies (if any)
        if let strategies = answer.strategies, !strategies.isEmpty {
            text += "\nRelated Strategies:\n"
            for (index, strategy) in strategies.enumerated() {
                text += "\(index + 1). \(strategy.description)\n"
            }
        }

        // Footer
        text += "\n---\n"
        text += "Shared from attune - Evidence-based neurodiversity-affirming parenting guidance\n"

        return text
    }

    /// Format answer as markdown
    static func formatAsMarkdown(answer: ContentAnswer, question: String? = nil) -> String {
        var markdown = ""

        // Question (if provided)
        if let question = question {
            markdown += "## Question\n\n"
            markdown += "\(question)\n\n"
        }

        // Answer section
        markdown += "## Answer\n\n"
        markdown += "\(answer.content)\n\n"

        // Source section
        markdown += "## Source\n\n"
        markdown += "**\(answer.source.title)**"
        if let section = answer.source.section {
            markdown += " - \(section)"
        }
        markdown += "\n\n"

        // Author
        if let author = answer.source.author {
            markdown += "_By \(author)_\n\n"
        }

        // Credibility badge
        let credibilityEmoji = answer.source.credibilityLevel.emoji
        markdown += "**Credibility:** \(credibilityEmoji) \(answer.source.credibilityLevel.displayName)\n\n"
        markdown += "> \(answer.source.credibilityLevel.description)\n\n"

        // Strategies (if any)
        if let strategies = answer.strategies, !strategies.isEmpty {
            markdown += "## Related Strategies\n\n"
            for strategy in strategies {
                markdown += "- **\(strategy.category.displayName):** \(strategy.description)\n"
            }
            markdown += "\n"
        }

        // Footer
        markdown += "---\n\n"
        markdown += "_Shared from attune - Evidence-based neurodiversity-affirming parenting guidance_\n"

        return markdown
    }

    /// Format multiple bookmarks as a collection
    static func formatBookmarksAsText(bookmarks: [Bookmark]) -> String {
        var text = "My attune Bookmarks\n"
        text += String(repeating: "=", count: 40) + "\n\n"

        for (index, bookmark) in bookmarks.enumerated() {
            text += "[\(index + 1)] \(bookmark.question)\n"
            text += String(repeating: "-", count: 40) + "\n\n"
            text += formatAsText(answer: bookmark.answer, question: nil)
            text += "\n"
        }

        text += "Total: \(bookmarks.count) saved answer\(bookmarks.count == 1 ? "" : "s")\n"
        text += "Exported: \(Date().formatted(date: .long, time: .shortened))\n"

        return text
    }

    /// Format multiple bookmarks as markdown
    static func formatBookmarksAsMarkdown(bookmarks: [Bookmark]) -> String {
        var markdown = "# My attune Bookmarks\n\n"
        markdown += "_Saved answers from attune Q&A_\n\n"
        markdown += "---\n\n"

        for (index, bookmark) in bookmarks.enumerated() {
            markdown += "## \(index + 1). \(bookmark.question)\n\n"
            markdown += "_Bookmarked: \(bookmark.formattedDate)_\n\n"
            markdown += formatAsMarkdown(answer: bookmark.answer, question: nil)
            markdown += "\n"
        }

        markdown += "---\n\n"
        markdown += "**Total:** \(bookmarks.count) saved answer\(bookmarks.count == 1 ? "" : "s")  \n"
        markdown += "**Exported:** \(Date().formatted(date: .long, time: .shortened))\n"

        return markdown
    }
}

// MARK: - Extensions

extension CredibilityLevel {
    var emoji: String {
        switch self {
        case .peerReviewed:
            return "🔬"
        case .expertRecommended:
            return "✅"
        case .communityValidated:
            return "💜"
        }
    }
}

extension StrategyCategory {
    var displayName: String {
        switch self {
        case .sensory:
            return "Sensory"
        case .environmental:
            return "Environmental"
        case .communication:
            return "Communication"
        case .coRegulation:
            return "Co-Regulation"
        case .transition:
            return "Transition"
        case .other:
            return "Other"
        }
    }
}
