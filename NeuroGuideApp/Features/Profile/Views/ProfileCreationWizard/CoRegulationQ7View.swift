//
//  CoRegulationQ7View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 7: Post-Regulation Connection
//

import SwiftUI

struct CoRegulationQ7View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.postRegulationConnection.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Helper text
            if let helperText = CoRegulationQuestion.postRegulationConnection.helperText {
                Text(helperText)
                    .font(.ngBody)
                    .foregroundColor(.ngTextSecondary)
            }

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(PostRegulationBehavior.allCases, id: \.self) { behavior in
                    if behavior != .other {
                        CheckboxRow(
                            label: behavior.rawValue,
                            isSelected: viewModel.coRegulationAssessment.postRegulationConnection.contains(behavior),
                            action: { togglePostRegulation(behavior) }
                        )
                    }
                }

                // Other option with text field
                CheckboxRow(
                    label: "Other:",
                    isSelected: viewModel.coRegulationAssessment.postRegulationConnection.contains(.other),
                    action: { togglePostRegulation(.other) }
                )

                if viewModel.coRegulationAssessment.postRegulationConnection.contains(.other) {
                    TextField("Please specify", text: Binding(
                        get: { viewModel.coRegulationAssessment.postRegulationConnectionOther ?? "" },
                        set: { viewModel.coRegulationAssessment.postRegulationConnectionOther = $0 }
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

    private func togglePostRegulation(_ behavior: PostRegulationBehavior) {
        if viewModel.coRegulationAssessment.postRegulationConnection.contains(behavior) {
            viewModel.coRegulationAssessment.postRegulationConnection.removeAll { $0 == behavior }
        } else {
            viewModel.coRegulationAssessment.postRegulationConnection.append(behavior)
        }
    }
}

#Preview {
    NavigationView {
        CoRegulationQ7View(viewModel: ProfileCreationViewModel())
    }
}
