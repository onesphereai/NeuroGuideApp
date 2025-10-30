//
//  StarsView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Displays star rating (0-5 stars)
struct StarsView: View {
    let rating: Double // 0.0-5.0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: starImage(for: index))
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(formattedRating) out of 5 stars")
    }

    private func starImage(for index: Int) -> String {
        let filledStars = Int(rating)
        if index <= filledStars {
            return "star.fill"
        } else if index == filledStars + 1 && rating.truncatingRemainder(dividingBy: 1) >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }

    private var formattedRating: String {
        String(format: "%.1f", rating)
    }
}

// MARK: - Preview

struct StarsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            StarsView(rating: 0.0)
            StarsView(rating: 2.5)
            StarsView(rating: 4.0)
            StarsView(rating: 5.0)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
