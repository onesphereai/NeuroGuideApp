//
//  CoRegulationStepView.swift
//  NeuroGuide
//
//  Co-regulation assessment questionnaire step
//  Refactored for AT-41: Pagination with one question per page
//

import SwiftUI

struct CoRegulationStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel
    @State private var currentQuestion: CoRegulationQuestion = .currentPractices

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator at the top
            HStack {
                Spacer()
                NGProgressIndicator(question: currentQuestion)
                    .padding(.top, NGSpacing.md)
                    .padding(.trailing, NGSpacing.md)
            }

            // Paginated question views
            TabView(selection: $currentQuestion) {
                CoRegulationQ1View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.currentPractices)

                CoRegulationQ2View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.calmingStrategies)

                CoRegulationQ3View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.parentSelfRegulation)

                CoRegulationQ4View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.communicationApproach)

                CoRegulationQ5View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.physicalProximity)

                CoRegulationQ6View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.recoveryTime)

                CoRegulationQ7View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.postRegulationConnection)

                CoRegulationQ8View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.parentConfidence)

                CoRegulationQ9View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.supportNeeds)

                CoRegulationQ10View(viewModel: viewModel)
                    .tag(CoRegulationQuestion.specificScenarios)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation buttons
            HStack(spacing: NGSpacing.md) {
                // Previous button
                if !currentQuestion.isFirst {
                    NGSecondaryButton("Previous", icon: "chevron.left") {
                        withAnimation {
                            if let previous = currentQuestion.previous {
                                currentQuestion = previous
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Next/Done button
                NGPrimaryButton(
                    currentQuestion.isLast ? "Done" : "Next",
                    icon: currentQuestion.isLast ? nil : "chevron.right"
                ) {
                    withAnimation {
                        if let next = currentQuestion.next {
                            currentQuestion = next
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(NGSpacing.md)
        }
        .background(Color.ngBackground.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Co-regulation assessment, question \(currentQuestion.rawValue) of \(CoRegulationQuestion.totalCount)")
    }
}

// MARK: - Supporting Views
// These views are shared across multiple question views

struct CheckboxRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .ngPrimaryBlue : .ngTextSecondary)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
                Text(label)
                    .font(.ngBody)
                    .foregroundColor(.ngTextPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.vertical, NGSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct RadioRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NGSpacing.sm) {
                Image(systemName: isSelected ? "circle.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .ngPrimaryBlue : .ngTextSecondary)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
                Text(label)
                    .font(.ngBody)
                    .foregroundColor(.ngTextPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.vertical, NGSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct RatingRow: View {
    let label: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.sm) {
            Text(label)
                .font(.ngCallout)
                .foregroundColor(.ngTextPrimary)

            HStack(spacing: NGSpacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .foregroundColor(value <= rating ? .ngAccentOrange : .ngTextSecondary)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("\(value) stars")
                    .accessibilityAddTraits(value == rating ? .isSelected : [])
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(label), rating \(rating) out of 5")
    }
}

struct ScenarioTextRow: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: NGSpacing.sm) {
            Text(label)
                .font(.ngCallout)
                .fontWeight(.medium)
                .foregroundColor(.ngTextPrimary)

            TextField("What helps in this situation?", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .font(.ngBody)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    NavigationView {
        CoRegulationStepView(viewModel: ProfileCreationViewModel())
    }
}
