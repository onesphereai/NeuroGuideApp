//
//  CoRegulationQ6View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 6: Recovery Time Patterns
//

import SwiftUI

struct CoRegulationQ6View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.recoveryTime.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Helper text
            if let helperText = CoRegulationQuestion.recoveryTime.helperText {
                Text(helperText)
                    .font(.ngSubheadline)
                    .foregroundColor(.ngTextSecondary)
                    .italic()
            }

            // Options list
            VStack(alignment: .leading, spacing: NGSpacing.sm) {
                ForEach(RecoveryTime.allCases, id: \.self) { time in
                    RadioRow(
                        label: time.rawValue,
                        isSelected: viewModel.coRegulationAssessment.recoveryTime == time,
                        action: { viewModel.coRegulationAssessment.recoveryTime = time }
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
        CoRegulationQ6View(viewModel: ProfileCreationViewModel())
    }
}
