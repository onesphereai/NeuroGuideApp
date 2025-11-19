//
//  CoRegulationQ9View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 9: Support Needs
//

import SwiftUI

struct CoRegulationQ9View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.supportNeeds.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(SupportNeed.allCases, id: \.self) { need in
                    if need != .other {
                        CheckboxRow(
                            label: need.rawValue,
                            isSelected: viewModel.coRegulationAssessment.supportNeeds.contains(need),
                            action: { toggleSupportNeed(need) }
                        )
                    }
                }

                // Other option with text field
                CheckboxRow(
                    label: "Other:",
                    isSelected: viewModel.coRegulationAssessment.supportNeeds.contains(.other),
                    action: { toggleSupportNeed(.other) }
                )

                if viewModel.coRegulationAssessment.supportNeeds.contains(.other) {
                    TextField("Please specify", text: Binding(
                        get: { viewModel.coRegulationAssessment.supportNeedsOther ?? "" },
                        set: { viewModel.coRegulationAssessment.supportNeedsOther = $0 }
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

    private func toggleSupportNeed(_ need: SupportNeed) {
        if viewModel.coRegulationAssessment.supportNeeds.contains(need) {
            viewModel.coRegulationAssessment.supportNeeds.removeAll { $0 == need }
        } else {
            viewModel.coRegulationAssessment.supportNeeds.append(need)
        }
    }
}

#Preview {
    NavigationView {
        CoRegulationQ9View(viewModel: ProfileCreationViewModel())
    }
}
