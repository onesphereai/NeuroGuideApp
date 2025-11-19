//
//  AskNeuroGuideServices.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import Combine

// MARK: - Question Input Service

/// Handles voice and text input for questions
@MainActor
protocol QuestionInputService: AnyObject {
    var isRecording: Bool { get }
    var recognizedText: String { get }

    func startVoiceRecording() async throws
    func stopVoiceRecording() async throws -> String
    func submitTextQuestion(text: String, childID: UUID?) async throws -> Question
}

// MARK: - Search Service

/// Searches content library and handles conversational follow-ups
@MainActor
protocol ConversationalSearchService: AnyObject {
    func search(query: Question, context: ConversationContext?, profile: ChildProfile?) async throws -> SearchResult
    func addFollowUp(query: Question, context: ConversationContext) async throws -> SearchResult
    func getConversationHistory() -> [ConversationTurn]
    func clearConversation()
}

// MARK: - Bookmark Service

/// Manages saved strategies and answers
@MainActor
protocol BookmarkService: AnyObject {
    var bookmarkedAnswers: [ContentAnswer] { get }
    var bookmarkedStrategies: [Strategy] { get }

    func bookmarkAnswer(_ answer: ContentAnswer) async throws
    func unbookmarkAnswer(_ answer: ContentAnswer) async throws
    func isBookmarked(_ answer: ContentAnswer) -> Bool

    func bookmarkStrategy(_ strategy: Strategy) async throws
    func unbookmarkStrategy(_ strategy: Strategy) async throws
    func isBookmarked(_ strategy: Strategy) -> Bool
}

// MARK: - Source Attribution Service

/// Provides credibility information for content sources
protocol SourceAttributionService {
    func getSourceDetails(for source: ContentSource) -> SourceDetails
    func validateCredibility(for source: ContentSource) -> Bool
}

// MARK: - Supporting Types

struct SourceDetails {
    let source: ContentSource
    let fullCitation: String
    let researchBasis: String?
    let expertEndorsements: [String]
    let communityFeedback: [String]

    var displayAttribution: String {
        return "Source: \(source.displayName)"
    }
}
