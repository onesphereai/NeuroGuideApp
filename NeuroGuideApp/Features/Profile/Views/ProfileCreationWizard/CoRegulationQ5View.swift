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

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(PhysicalProximityPreference.allCases, id: \.self) { preference in
                    RadioRow(
                        label: preference.rawValue,
                        isSelected: viewModel.coRegulationAssessment.physicalProximityPreference == preference,
                        action: { viewModel.coRegulationAssessment.physicalProximityPreference = preference }
                    )
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
