//
//  RelatedQuestionsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// View displaying related questions based on article content
struct RelatedQuestionsView: View {
    let questions: [String]
    let onQuestionTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble.fill")
                    .foregroundColor(.purple)
                    .font(.subheadline)

                Text("Related Questions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(questions, id: \.self) { question in
                    Button(action: {
                        onQuestionTap(question)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left")
                                .font(.caption)
                                .foregroundColor(.purple)

                            Text(question)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    RelatedQuestionsView(
        questions: [
            "What are early warning signs of a meltdown?",
            "How is a shutdown different from a meltdown?",
            "What should I do during a meltdown?"
        ],
        onQuestionTap: { question in
            print("Tapped: \(question)")
        }
    )
    .padding()
}
