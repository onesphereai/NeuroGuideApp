//
//  CoRegulationQ5View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 5: Physical Proximity Preferences
//

import SwiftUI

struct CoRegulationQ5View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.physicalProximity.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Helper text
            if let helperText = CoRegulationQuestion.physicalProximity.helperText {
                Text(helperText)
                    .font(.ngSubheadline)
                    .foregroundColor(.ngTextSecondary)
                    .italic()
            }

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(PhysicalProximityPreference.allCases, id: \.self) { preference in
                    if preference != .other {
                        RadioRow(
                            label: preference.rawValue,
                            isSelected: viewModel.coRegulationAssessment.physicalProximityPreference == preference,
                            action: { viewModel.coRegulationAssessment.physicalProximityPreference = preference }
                        )
                    }
                }

                // Other option with text field
                RadioRow(
                    label: "Other:",
                    isSelected: viewModel.coRegulationAssessment.physicalProximityPreference == .other,
                    action: { viewModel.coRegulationAssessment.physicalProximityPreference = .other }
                )

                if viewModel.coRegulationAssessment.physicalProximityPreference == .other {
                    TextField("Please specify", text: Binding(
                        get: { viewModel.coRegulationAssessment.physicalProximityPreferenceOther ?? "" },
                        set: { viewModel.coRegulationAssessment.physicalProximityPreferenceOther = $0 }
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
        CoRegulationQ5View(viewModel: ProfileCreationViewModel())
    }
}
