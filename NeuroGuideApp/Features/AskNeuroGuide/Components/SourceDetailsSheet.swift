//
//  SourceDetailsSheet.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// Sheet showing detailed information about a content source
struct SourceDetailsSheet: View {
    let source: ContentSource
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(source.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let section = source.section {
                            Text(section)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Credibility badge
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Source Credibility")
                            .font(.headline)

                        CredibilityBadge(level: source.credibilityLevel)

                        Text(source.credibilityLevel.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Author information
                    if let author = source.author {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Author")
                                .font(.headline)

                            HStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)

                                Text(author)
                                    .font(.body)
                            }

                            authorDescription(for: author)
                        }

                        Divider()
                    }

                    // What this means
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About This Source")
                            .font(.headline)

                        Text(sourceDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Privacy note
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)

                            Text("Privacy Note")
                                .font(.headline)
                        }

                        Text("All content is stored on your device. No data is sent to external servers.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Source Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func authorDescription(for author: String) -> some View {
        Group {
            switch author {
            case "Dr. Mona Delahooke":
                Text("Clinical psychologist specializing in infant and early childhood mental health with expertise in neurodiversity-affirming approaches.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            default:
                Text("Expert contributor to attune's evidence-based content library.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var sourceDescription: String {
        switch source.credibilityLevel {
        case .peerReviewed:
            return "This content is based on peer-reviewed research published in academic journals. It represents evidence-based practices validated through scientific study."
        case .expertRecommended:
            return "This content is recommended by experts in neurodiversity, child development, and mental health. It reflects current best practices in neurodiversity-affirming support."
        case .communityValidated:
            return "This content has been validated by the neurodivergent community, including autistic adults and parents. It represents lived experience and community wisdom."
        }
    }
}

// MARK: - Preview

#Preview {
    SourceDetailsSheet(
        source: ContentSource(
            title: "Understanding Meltdowns vs Tantrums",
            section: "Crisis Support",
            author: "Dr. Mona Delahooke",
            credibilityLevel: .expertRecommended
        )
    )
}
