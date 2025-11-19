//
//  CoRegulationQ2View.swift
//  NeuroGuide
//
//  Created for AT-19: Co-Regulation Q2 Rating
//  Question 2: Rate helpfulness of 17 calming strategies (1-5 scale)
//

import SwiftUI

struct CoRegulationQ2View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel
    @State private var showingAddCustomStrategy = false
    
    private let maxCustomStrategies = 5
    
    private var customStrategiesCount: Int {
        viewModel.coRegulationAssessment.strategyRatings.filter { $0.isCustom }.count
    }
    
    private var canAddMoreCustomStrategies: Bool {
        customStrategiesCount < maxCustomStrategies
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question header
            VStack(alignment: .leading, spacing: 8) {
                Text("2. How helpful have these calming supports been for your child?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Rate each one from 1–5 (1 = not helpful, 5 = very helpful). Tap a star again to mark 'Haven't tried'.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Strategy ratings list
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.coRegulationAssessment.strategyRatings) { strategy in
                    if let index = viewModel.coRegulationAssessment.strategyRatings.firstIndex(where: { $0.id == strategy.id }) {
                        StrategyRatingRow(
                            strategy: strategy,
                            rating: Binding(
                                get: { viewModel.coRegulationAssessment.strategyRatings[index].rating },
                                set: { newValue in
                                    viewModel.coRegulationAssessment.strategyRatings[index].rating = newValue
                                    viewModel.coRegulationAssessment.strategyRatings[index].lastUpdated = Date()
                                }
                            ),
                            onDelete: strategy.isCustom ? {
                                deleteCustomStrategy(at: index)
                            } : nil
                        )
                        .padding(.horizontal)
                        
                        if index < viewModel.coRegulationAssessment.strategyRatings.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Add Custom Strategy button
            Button {
                showingAddCustomStrategy = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Custom Strategy")
                    Spacer()
                    if !canAddMoreCustomStrategies {
                        Text("(\(maxCustomStrategies) max)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(canAddMoreCustomStrategies ? .blue : .gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .disabled(!canAddMoreCustomStrategies)
        }
        .sheet(isPresented: $showingAddCustomStrategy) {
            AddCustomStrategySheet { newStrategy in
                addCustomStrategy(newStrategy)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addCustomStrategy(_ strategy: CalmingStrategyRating) {
        guard canAddMoreCustomStrategies else { return }
        viewModel.coRegulationAssessment.strategyRatings.append(strategy)
        viewModel.coRegulationAssessment.lastUpdated = Date()
    }
    
    private func deleteCustomStrategy(at index: Int) {
        viewModel.coRegulationAssessment.strategyRatings.remove(at: index)
        viewModel.coRegulationAssessment.lastUpdated = Date()
    }
}

#Preview {
    NavigationView {
        ScrollView {
            CoRegulationQ2View(viewModel: ProfileCreationViewModel())
                .padding()
        }
    }
}
