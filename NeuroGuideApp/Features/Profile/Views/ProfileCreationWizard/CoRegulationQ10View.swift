//
//  CoRegulationQ10View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 10: Specific Scenarios (Optional)
//

import SwiftUI

struct CoRegulationQ10View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question heading
            Text("10. Specific Scenarios (Optional)")
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Scenario text fields with enhanced rows
            VStack(alignment: .leading, spacing: NGSpacing.md) {
                EnhancedScenarioTextRow(
                    label: "Morning transitions",
                    subtitle: "Getting out the door, starting the day, breakfast routine",
                    placeholder: "E.g., visual schedule, extra time, calm music...",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.morningTransitionsStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.morningTransitionsStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                EnhancedScenarioTextRow(
                    label: "Bedtime routines",
                    subtitle: "Wind down, brushing teeth, settling in for sleep",
                    placeholder: "E.g., dim lights, white noise, same order every night...",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.bedtimeRoutinesStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.bedtimeRoutinesStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                EnhancedScenarioTextRow(
                    label: "Public meltdowns",
                    subtitle: "Store, playground, crowded spaces, out in the community",
                    placeholder: "E.g., leaving quickly, firm hug, quiet corner...",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.publicMeltdownsStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.publicMeltdownsStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                EnhancedScenarioTextRow(
                    label: "Sibling conflicts",
                    subtitle: "Fights over toys, attention, fairness struggles",
                    placeholder: "E.g., separate first, validate both, redirect...",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.siblingConflictsStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.siblingConflictsStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                EnhancedScenarioTextRow(
                    label: "Unexpected changes",
                    subtitle: "Plans shifting, surprises, disruptions to routine",
                    placeholder: "E.g., prep ahead when possible, simple explanation, extra patience...",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.unexpectedChangesStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.unexpectedChangesStrategy = $0.isEmpty ? nil : $0 }
                    )
                )
            }

            Spacer()
        }
        .padding(NGSpacing.md)
    }
}

#Preview {
    NavigationView {
        CoRegulationQ10View(viewModel: ProfileCreationViewModel())
    }
}
