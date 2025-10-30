//
//  SuggestedQuestionsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// View showing suggested follow-up questions based on conversation context
struct SuggestedQuestionsView: View {
    let questions: [String]
    let onQuestionTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)

                Text("You might also want to know...")
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
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text(question)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    SuggestedQuestionsView(
        questions: [
            "How long do meltdowns usually last?",
            "What's the difference between a meltdown and a shutdown?",
            "How can I prevent meltdowns from happening?"
        ],
        onQuestionTap: { question in
            print("Tapped: \(question)")
        }
    )
    .padding()
}
