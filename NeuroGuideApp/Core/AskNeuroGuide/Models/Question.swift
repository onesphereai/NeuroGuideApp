//
//  Question.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation

/// Represents a question asked by the parent
struct Question: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let inputMethod: QuestionInputMethod
    let timestamp: Date
    let childID: UUID?

    init(
        id: UUID = UUID(),
        text: String,
        inputMethod: QuestionInputMethod,
        timestamp: Date = Date(),
        childID: UUID? = nil
    ) {
        self.id = id
        self.text = text
        self.inputMethod = inputMethod
        self.timestamp = timestamp
        self.childID = childID
    }
}

/// How the question was entered
enum QuestionInputMethod: String, Codable {
    case voice = "voice"
    case text = "text"

    var displayName: String {
        switch self {
        case .voice:
            return "Voice"
        case .text:
            return "Text"
        }
    }

    var icon: String {
        switch self {
        case .voice:
            return "mic.fill"
        case .text:
            return "keyboard.fill"
        }
    }
}
