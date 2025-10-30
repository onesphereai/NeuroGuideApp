//
//  CommunicationModeRow.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.2)
//

import SwiftUI

/// Selectable row for communication mode
struct CommunicationModeRow: View {
    let mode: CommunicationMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Radio button
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                    .accessibilityHidden(true)

                // Mode icon
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                    .accessibilityHidden(true)

                // Mode info
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel("\(mode.rawValue). \(mode.description)")
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
    }
}

// MARK: - Preview

struct CommunicationModeRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            CommunicationModeRow(
                mode: .verbal,
                isSelected: true,
                onTap: {}
            )

            CommunicationModeRow(
                mode: .minimallyVerbal,
                isSelected: false,
                onTap: {}
            )

            CommunicationModeRow(
                mode: .nonVerbal,
                isSelected: false,
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
