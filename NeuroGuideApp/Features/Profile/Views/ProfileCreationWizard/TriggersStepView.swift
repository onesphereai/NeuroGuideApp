//
//  TriggersStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.3)
//

import SwiftUI

/// Fourth step: Triggers and strategies
/// Full implementation for Bolt 3.3
struct TriggersStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel
    @State private var showAddTrigger = false
    @State private var showAddStrategy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions header
                instructionsHeader

                // Triggers section
                triggersSection

                // Divider
                Divider()
                    .padding(.vertical, 8)

                // Strategies section
                strategiesSection

                // Info card
                infoCard

                Spacer(minLength: 20)
            }
            .padding()
        }
        .sheet(isPresented: $showAddTrigger) {
            AddTriggerSheet(isPresented: $showAddTrigger) { trigger in
                viewModel.addTrigger(trigger)
            }
        }
        .sheet(isPresented: $showAddStrategy) {
            AddStrategySheet(isPresented: $showAddStrategy) { strategy in
                viewModel.addStrategy(strategy)
            }
        }
    }

    // MARK: - Instructions Header

    private var instructionsHeader: some View {
        VStack(spacing: 8) {
            Text("Knowing what triggers dysregulation and what strategies help your child can guide us in providing personalized support.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Triggers Section

    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Known Triggers")
                    .font(.headline)

                Text("What situations or inputs tend to lead to dysregulation? (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.triggers.isEmpty {
                emptyStateCard(
                    icon: "exclamationmark.triangle",
                    iconColor: .orange,
                    message: "No triggers added yet. It's okay to skip this—you can add them later in your profile."
                )
            } else {
                ForEach(viewModel.triggers) { trigger in
                    TriggerRow(trigger: trigger) {
                        viewModel.removeTrigger(id: trigger.id)
                    }
                }
            }

            Button(action: { showAddTrigger = true }) {
                Label("Add Trigger", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add new trigger")
            .accessibilityHint("Opens a form to add a new trigger")
        }
    }

    // MARK: - Strategies Section

    private var strategiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Soothing Strategies")
                    .font(.headline)

                Text("What strategies help your child when they're overwhelmed? (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.strategies.isEmpty {
                emptyStateCard(
                    icon: "heart.circle",
                    iconColor: .green,
                    message: "No strategies added yet. We'll suggest some based on your child's profile."
                )
            } else {
                ForEach(viewModel.strategies) { strategy in
                    StrategyRow(strategy: strategy) {
                        viewModel.removeStrategy(id: strategy.id)
                    }
                }
            }

            Button(action: { showAddStrategy = true }) {
                Label("Add Strategy", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add new strategy")
            .accessibilityHint("Opens a form to add a new soothing strategy")
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        InfoCard(
            icon: "lightbulb.fill",
            title: "Personalized Guidance",
            message: "This information helps us recommend strategies during moments of dysregulation. We'll learn over time which strategies work best for your child."
        )
    }

    // MARK: - Empty State Helper

    private func emptyStateCard(icon: String, iconColor: Color, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor.opacity(0.6))

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Preview

struct TriggersStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty state
            TriggersStepView(viewModel: ProfileCreationViewModel())
                .previewDisplayName("Empty State")

            // With data
            TriggersStepView(viewModel: {
                let vm = ProfileCreationViewModel()
                vm.addTrigger(Trigger(description: "Loud sudden noises", category: .sensory))
                vm.addTrigger(Trigger(description: "Schedule changes", category: .routine))
                vm.addStrategy(Strategy(description: "Deep pressure hugs", category: .sensory))
                return vm
            }())
                .previewDisplayName("With Data")

            // Dark mode
            TriggersStepView(viewModel: ProfileCreationViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
