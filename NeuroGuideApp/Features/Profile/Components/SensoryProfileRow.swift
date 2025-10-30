//
//  SensoryProfileRow.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.2)
//

import SwiftUI

/// Row component for selecting sensory profile for a specific sense
struct SensoryProfileRow: View {
    let sense: SenseType
    @Binding var profile: SensoryProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sense header
            HStack(spacing: 12) {
                Image(systemName: sense.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sense.displayName)
                        .font(.headline)
                    Text(sense.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            // Profile picker (segmented control)
            Picker("Sensory profile for \(sense.displayName)", selection: $profile) {
                ForEach(SensoryProfile.allCases, id: \.self) { profile in
                    Text(profile.rawValue)
                        .tag(profile)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Sensory profile for \(sense.displayName)")
            .accessibilityValue(profile.rawValue)
            .accessibilityHint(profile.description)

            // Profile description
            Text(profile.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

struct SensoryProfileRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SensoryProfileRow(
                sense: .touch,
                profile: .constant(.seeking)
            )

            SensoryProfileRow(
                sense: .sound,
                profile: .constant(.avoiding)
            )

            SensoryProfileRow(
                sense: .movement,
                profile: .constant(.neutral)
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
