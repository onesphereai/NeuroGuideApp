//
//  CoRegulationQ3View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 3: Parent's Self-Regulation
//

import SwiftUI

struct CoRegulationQ3View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.parentSelfRegulation.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Helper text
            if let helperText = CoRegulationQuestion.parentSelfRegulation.helperText {
                Text(helperText)
                    .font(.ngSubheadline)
                    .foregroundColor(.ngTextSecondary)
                    .italic()
            }

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(ParentSelfRegulationStrategy.allCases, id: \.self) { strategy in
                    if strategy != .other {
                        CheckboxRow(
                            label: strategy.rawValue,
                            isSelected: viewModel.coRegulationAssessment.parentSelfRegulation.contains(strategy),
                            action: { toggleSelfRegulation(strategy) }
                        )
                    }
                }

                // Other option with text field
                CheckboxRow(
                    label: "Other:",
                    isSelected: viewModel.coRegulationAssessment.parentSelfRegulation.contains(.other),
                    action: { toggleSelfRegulation(.other) }
                )

                if viewModel.coRegulationAssessment.parentSelfRegulation.contains(.other) {
                    TextField("Please specify", text: Binding(
                        get: { viewModel.coRegulationAssessment.parentSelfRegulationOther ?? "" },
                        set: { viewModel.coRegulationAssessment.parentSelfRegulationOther = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading, 32)
                }
            }

            Spacer()
        }
        .padding(NGSpacing.md)
    }

    // MARK: - Helper Methods

    private func toggleSelfRegulation(_ strategy: ParentSelfRegulationStrategy) {
        if viewModel.coRegulationAssessment.parentSelfRegulation.contains(strategy) {
            viewModel.coRegulationAssessment.parentSelfRegulation.removeAll { $0 == strategy }
        } else {
            viewModel.coRegulationAssessment.parentSelfRegulation.append(strategy)
        }
    }
}

#Preview {
    NavigationView {
        CoRegulationQ3View(viewModel: ProfileCreationViewModel())
    }
}
