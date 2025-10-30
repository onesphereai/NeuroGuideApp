//
//  StrategyRow.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Row component for displaying a strategy
struct StrategyRow: View {
    let strategy: Strategy
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: strategy.category.icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)
                .accessibilityHidden(true)

            // Description, category, and stats
            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.description)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(strategy.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    // Stars (only if used at least once)
                    if strategy.usageCount > 0 {
                        StarsView(rating: strategy.effectivenessRating)

                        // Usage count
                        Text("Used \(strategy.usageCount) time\(strategy.usageCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Not yet used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete strategy")
            .accessibilityHint("Removes \(strategy.description) from the list")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

struct StrategyRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            // Unused strategy
            StrategyRow(
                strategy: Strategy(
                    description: "Deep pressure hugs",
                    category: .sensory,
                    effectivenessRating: 0.0
                ),
                onDelete: {}
            )

            // Used strategy
            StrategyRow(
                strategy: {
                    var strategy = Strategy(
                        description: "Jumping on trampoline",
                        category: .sensory,
                        effectivenessRating: 4.5
                    )
                    strategy.usageCount = 12
                    return strategy
                }(),
                onDelete: {}
            )

            // Moderately effective
            StrategyRow(
                strategy: {
                    var strategy = Strategy(
                        description: "Quiet reading time",
                        category: .environmental,
                        effectivenessRating: 3.0
                    )
                    strategy.usageCount = 5
                    return strategy
                }(),
                onDelete: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
