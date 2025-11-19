//
//  CoRegulationQ8View.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Question 8: Parent Confidence
//

import SwiftUI

struct CoRegulationQ8View: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.lg) {
            // Question text
            Text(CoRegulationQuestion.parentConfidence.questionText)
                .font(.ngTitle3)
                .foregroundColor(.ngTextPrimary)

            // Slider with labels
            VStack(alignment: .leading, spacing: NGSpacing.md) {
                HStack {
                    Text("Very uncertain")
                        .font(.ngCaption1)
                        .foregroundColor(.ngTextSecondary)
                    Spacer()
                    Text("Very confident")
                        .font(.ngCaption1)
                        .foregroundColor(.ngTextSecondary)
                }

                Slider(value: Binding(
                    get: { Double(viewModel.coRegulationAssessment.parentConfidence ?? 3) },
                    set: { viewModel.coRegulationAssessment.parentConfidence = Int($0) }
                ), in: 1...5, step: 1)
                .accentColor(.ngPrimaryBlue)

                Text("Level: \(viewModel.coRegulationAssessment.parentConfidence ?? 3)")
                    .font(.ngTitle2)
                    .fontWeight(.semibold)
                    .foregroundColor(.ngPrimaryBlue)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, NGSpacing.sm)
            }
            .padding(.horizontal, NGSpacing.sm)

            Spacer()
        }
        .padding(NGSpacing.md)
    }
}

#Preview {
    NavigationView {
        CoRegulationQ8View(viewModel: ProfileCreationViewModel())
    }
}
