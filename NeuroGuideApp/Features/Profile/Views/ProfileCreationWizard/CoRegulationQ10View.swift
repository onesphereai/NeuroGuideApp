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
            // Question text
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                Text(CoRegulationQuestion.specificScenarios.questionText)
                    .font(.ngTitle3)
                    .foregroundColor(.ngTextPrimary)

                if let helperText = CoRegulationQuestion.specificScenarios.helperText {
                    Text(helperText)
                        .font(.ngSubheadline)
                        .foregroundColor(.ngTextSecondary)
                }
            }

            // Scenario text fields
            VStack(alignment: .leading, spacing: NGSpacing.md) {
                ScenarioTextRow(
                    label: "Morning transitions:",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.morningTransitionsStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.morningTransitionsStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                ScenarioTextRow(
                    label: "Bedtime routines:",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.bedtimeRoutinesStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.bedtimeRoutinesStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                ScenarioTextRow(
                    label: "Public meltdowns:",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.publicMeltdownsStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.publicMeltdownsStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                ScenarioTextRow(
                    label: "Sibling conflicts:",
                    text: Binding(
                        get: { viewModel.coRegulationAssessment.siblingConflictsStrategy ?? "" },
                        set: { viewModel.coRegulationAssessment.siblingConflictsStrategy = $0.isEmpty ? nil : $0 }
                    )
                )

                ScenarioTextRow(
                    label: "Unexpected changes:",
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
