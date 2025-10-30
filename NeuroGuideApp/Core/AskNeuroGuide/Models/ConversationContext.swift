//
//  ConversationContext.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Context for conversational follow-up questions
struct ConversationContext: Codable, Equatable {
    let conversationID: UUID
    let turns: [ConversationTurn]
    let topics: [String]
    let lastUpdate: Date

    init(
        conversationID: UUID = UUID(),
        turns: [ConversationTurn] = [],
        topics: [String] = [],
        lastUpdate: Date = Date()
    ) {
        self.conversationID = conversationID
        self.turns = turns
        self.topics = topics
        self.lastUpdate = lastUpdate
    }

    /// Most recent question
    var currentQuestion: Question? {
        return turns.last?.question
    }

    /// Add a new turn to the conversation
    func addingTurn(_ turn: ConversationTurn) -> ConversationContext {
        var updatedTurns = turns
        updatedTurns.append(turn)

        return ConversationContext(
            conversationID: conversationID,
            turns: updatedTurns,
            topics: topics,
            lastUpdate: Date()
        )
    }

    /// Start a new conversation (clear context)
    static func new() -> ConversationContext {
        return ConversationContext()
    }
}

/// Single turn in a conversation (question + answer)
struct ConversationTurn: Identifiable, Codable, Equatable {
    let id: UUID
    let question: Question
    let result: SearchResult
    let timestamp: Date

    init(
        id: UUID = UUID(),
        question: Question,
        result: SearchResult,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.question = question
        self.result = result
        self.timestamp = timestamp
    }
}
