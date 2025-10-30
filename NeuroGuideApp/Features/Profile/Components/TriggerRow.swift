//
//  TriggerRow.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Row component for displaying a trigger
struct TriggerRow: View {
    let trigger: Trigger
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: trigger.category.icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)
                .accessibilityHidden(true)

            // Description and category
            VStack(alignment: .leading, spacing: 4) {
                Text(trigger.description)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(trigger.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete trigger")
            .accessibilityHint("Removes \(trigger.description) from the list")
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

struct TriggerRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            TriggerRow(
                trigger: Trigger(
                    description: "Loud sudden noises",
                    category: .sensory
                ),
                onDelete: {}
            )

            TriggerRow(
                trigger: Trigger(
                    description: "Unexpected schedule changes",
                    category: .routine
                ),
                onDelete: {}
            )

            TriggerRow(
                trigger: Trigger(
                    description: "Crowded spaces",
                    category: .environmental
                ),
                onDelete: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
