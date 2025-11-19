//
//  StrategyRatingRow.swift
//  NeuroGuide
//
//  Created for AT-19: Co-Regulation Q2 Rating
//  Reusable component for rating calming strategies 1-5
//

import SwiftUI

/// Row component for rating a single calming strategy
struct StrategyRatingRow: View {
    let strategy: CalmingStrategyRating
    @Binding var rating: Int?
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Strategy name with custom badge
            HStack(alignment: .top, spacing: 8) {
                Text(strategy.strategyName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if strategy.isCustom {
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Delete button for custom strategies
                if onDelete != nil && strategy.isCustom {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Example text (gray subtitle)
            if let example = strategy.example {
                Text(example)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Rating stars
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        if rating == value {
                            // Tap same star to clear rating (Haven't tried)
                            rating = nil
                        } else {
                            rating = value
                        }
                    } label: {
                        Image(systemName: value <= (rating ?? 0) ? "star.fill" : "star")
                            .foregroundColor(value <= (rating ?? 0) ? .yellow : .gray)
                            .font(.title3)
                    }
                }
                
                // "Haven't tried" indicator
                if rating == nil {
                    Text("Haven't tried")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        StrategyRatingRow(
            strategy: CalmingStrategyFactory.createDefaultStrategies()[0],
            rating: .constant(4)
        )
        
        StrategyRatingRow(
            strategy: CalmingStrategyFactory.createDefaultStrategies()[1],
            rating: .constant(nil)
        )
    }
    .padding()
}
