//
//  CoRegulationQ1View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 1: Current Co-Regulation Practices
//

import SwiftUI

struct CoRegulationQ1View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.currentPractices.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Helper text
            if let helperText = CoRegulationQuestion.currentPractices.helperText {
                Text(helperText)
                    .font(.ngSubheadline)
                    .foregroundColor(.ngTextSecondary)
            }

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(CoRegulationPractice.allCases, id: \.self) { practice in
                    if practice != .other {
                        CheckboxRow(
                            label: practice.rawValue,
                            isSelected: viewModel.coRegulationAssessment.currentPractices.contains(practice),
                            action: { togglePractice(practice) }
                        )
                    }
                }

                // Other option with text field
                CheckboxRow(
                    label: "Other:",
                    isSelected: viewModel.coRegulationAssessment.currentPractices.contains(.other),
                    action: { togglePractice(.other) }
                )

                if viewModel.coRegulationAssessment.currentPractices.contains(.other) {
                    TextField("Please specify", text: Binding(
                        get: { viewModel.coRegulationAssessment.currentPracticesOther ?? "" },
                        set: { viewModel.coRegulationAssessment.currentPracticesOther = $0 }
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

    private func togglePractice(_ practice: CoRegulationPractice) {
        if viewModel.coRegulationAssessment.currentPractices.contains(practice) {
            viewModel.coRegulationAssessment.currentPractices.removeAll { $0 == practice }
        } else {
            viewModel.coRegulationAssessment.currentPractices.append(practice)
        }
    }
}

#Preview {
    NavigationView {
        CoRegulationQ1View(viewModel: ProfileCreationViewModel())
    }
}
