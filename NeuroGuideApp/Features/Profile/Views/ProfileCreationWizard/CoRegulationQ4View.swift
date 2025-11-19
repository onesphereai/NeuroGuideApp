//
//  CoRegulationQ4View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 4: Communication During Dysregulation
//

import SwiftUI

struct CoRegulationQ4View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.communicationApproach.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(CommunicationApproach.allCases, id: \.self) { approach in
                    if approach != .other {
                        RadioRow(
                            label: approach.rawValue,
                            isSelected: viewModel.coRegulationAssessment.communicationApproach == approach,
                            action: { viewModel.coRegulationAssessment.communicationApproach = approach }
                        )
                    }
                }

                // Other option with text field
                RadioRow(
                    label: "Other:",
                    isSelected: viewModel.coRegulationAssessment.communicationApproach == .other,
                    action: { viewModel.coRegulationAssessment.communicationApproach = .other }
                )

                if viewModel.coRegulationAssessment.communicationApproach == .other {
                    TextField("Please specify", text: Binding(
                        get: { viewModel.coRegulationAssessment.communicationApproachOther ?? "" },
                        set: { viewModel.coRegulationAssessment.communicationApproachOther = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading, 32)
                }
            }

            Spacer()
        }
        .padding(NGSpacing.md)
    }
}

#Preview {
    NavigationView {
        CoRegulationQ4View(viewModel: ProfileCreationViewModel())
    }
}
