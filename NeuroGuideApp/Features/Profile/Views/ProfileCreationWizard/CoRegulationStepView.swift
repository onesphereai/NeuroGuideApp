//
//  CoRegulationStepView.swift
//  NeuroGuide
//
//  Co-regulation assessment questionnaire step
//

import SwiftUI

struct CoRegulationStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Q1: Current Co-Regulation Practices
                questionSection(number: 1, title: "When your child becomes overwhelmed or dysregulated, how do you usually respond?") {
                    Text("Select all that apply. No judgment — every parent does their best.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    ForEach(CoRegulationPractice.allCases, id: \.self) { practice in
                        if practice != .other {
                            CheckboxRow(
                                label: practice.rawValue,
                                isSelected: viewModel.coRegulationAssessment.currentPractices.contains(practice),
                                action: { togglePractice(practice) }
                            )
                        }
                    }

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

                Divider()

                // Q2: Effective Calming Strategies (Ratings)
                questionSection(number: 2, title: "Rate which strategies have helped your child return to calm (1-5 scale)") {
                    RatingRow(label: "Deep pressure (hugs, weighted items)", rating: Binding(
                        get: { viewModel.coRegulationAssessment.deepPressureRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.deepPressureRating = $0 }
                    ))

                    RatingRow(label: "Rhythmic movement (rocking, swaying)", rating: Binding(
                        get: { viewModel.coRegulationAssessment.rhythmicMovementRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.rhythmicMovementRating = $0 }
                    ))

                    RatingRow(label: "Quiet/dimmed environment", rating: Binding(
                        get: { viewModel.coRegulationAssessment.quietEnvironmentRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.quietEnvironmentRating = $0 }
                    ))

                    RatingRow(label: "Favorite sensory items", rating: Binding(
                        get: { viewModel.coRegulationAssessment.sensoryItemsRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.sensoryItemsRating = $0 }
                    ))

                    RatingRow(label: "Predictable routines", rating: Binding(
                        get: { viewModel.coRegulationAssessment.routinesRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.routinesRating = $0 }
                    ))

                    RatingRow(label: "Verbal reassurance", rating: Binding(
                        get: { viewModel.coRegulationAssessment.verbalReassuranceRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.verbalReassuranceRating = $0 }
                    ))

                    RatingRow(label: "Silent presence", rating: Binding(
                        get: { viewModel.coRegulationAssessment.silentPresenceRating ?? 3 },
                        set: { viewModel.coRegulationAssessment.silentPresenceRating = $0 }
                    ))
                }

                Divider()

                // Q3: Parent's Self-Regulation
                VStack(alignment: .leading, spacing: 12) {
                    Text("3. When your child is overwhelmed, how do you usually manage your own emotions?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Choose all that apply. No right or wrong answers — every parent is doing their best.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                    
                    ForEach(ParentSelfRegulationStrategy.allCases, id: \.self) { strategy in
                        if strategy != .other {
                            CheckboxRow(
                                label: strategy.rawValue,
                                isSelected: viewModel.coRegulationAssessment.parentSelfRegulation.contains(strategy),
                                action: { toggleSelfRegulation(strategy) }
                            )
                        }
                    }

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
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Divider()

                // Q4: Communication During Dysregulation
                questionSection(number: 4, title: "What communication approach works best when your child is upset?") {
                    ForEach(CommunicationApproach.allCases, id: \.self) { approach in
                        if approach != .other {
                            RadioRow(
                                label: approach.rawValue,
                                isSelected: viewModel.coRegulationAssessment.communicationApproach == approach,
                                action: { viewModel.coRegulationAssessment.communicationApproach = approach }
                            )
                        }
                    }

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

                Divider()

                // Q5: Physical Proximity Preferences
                questionSection(number: 5, title: "During dysregulation, does your child typically:") {
                    ForEach(PhysicalProximityPreference.allCases, id: \.self) { preference in
                        RadioRow(
                            label: preference.rawValue,
                            isSelected: viewModel.coRegulationAssessment.physicalProximityPreference == preference,
                            action: { viewModel.coRegulationAssessment.physicalProximityPreference = preference }
                        )
                    }
                }

                Divider()

                // Q6: Recovery Time Patterns
                questionSection(number: 6, title: "How long does it typically take your child to return to baseline after dysregulation?") {
                    ForEach(RecoveryTime.allCases, id: \.self) { time in
                        RadioRow(
                            label: time.rawValue,
                            isSelected: viewModel.coRegulationAssessment.recoveryTime == time,
                            action: { viewModel.coRegulationAssessment.recoveryTime = time }
                        )
                    }
                }

                Divider()

                // Q7: Post-Regulation Connection
                questionSection(number: 7, title: "After a dysregulation episode, how does your child reconnect?") {
                    ForEach(PostRegulationBehavior.allCases, id: \.self) { behavior in
                        if behavior != .other {
                            CheckboxRow(
                                label: behavior.rawValue,
                                isSelected: viewModel.coRegulationAssessment.postRegulationConnection.contains(behavior),
                                action: { togglePostRegulation(behavior) }
                            )
                        }
                    }

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

                Divider()

                // Q8: Parent Confidence
                questionSection(number: 8, title: "How confident do you feel in co-regulating with your child?") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Very uncertain")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Very confident")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(viewModel.coRegulationAssessment.parentConfidence ?? 3) },
                            set: { viewModel.coRegulationAssessment.parentConfidence = Int($0) }
                        ), in: 1...5, step: 1)

                        Text("Level: \(viewModel.coRegulationAssessment.parentConfidence ?? 3)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Q9: Support Needs
                questionSection(number: 9, title: "What would help you most in supporting your child's regulation?") {
                    ForEach(SupportNeed.allCases, id: \.self) { need in
                        if need != .other {
                            CheckboxRow(
                                label: need.rawValue,
                                isSelected: viewModel.coRegulationAssessment.supportNeeds.contains(need),
                                action: { toggleSupportNeed(need) }
                            )
                        }
                    }

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

                Divider()

                // Q10: Specific Scenarios (Optional)
                VStack(alignment: .leading, spacing: 16) {
                    Text("10. Specific Scenarios (Optional)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("What typically helps in these situations?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScenarioTextRow(
                        label: "Morning transitions:",
                        text: Binding(
                            get: { viewModel.coRegulationAssessment.morningTransitionsStrategy ?? "" },
                            set: { viewModel.coRegulationAssessment.morningTransitionsStrategy = $0.isEmpty ? nil : $0 }
                        )
                    )

                    ScenarioTextRow(
                        label: "Bedtime routines:",
                        text: Binding(
                            get: { viewModel.coRegulationAssessment.bedtimeRoutinesStrategy ?? "" },
                            set: { viewModel.coRegulationAssessment.bedtimeRoutinesStrategy = $0.isEmpty ? nil : $0 }
                        )
                    )

                    ScenarioTextRow(
                        label: "Public meltdowns:",
                        text: Binding(
                            get: { viewModel.coRegulationAssessment.publicMeltdownsStrategy ?? "" },
                            set: { viewModel.coRegulationAssessment.publicMeltdownsStrategy = $0.isEmpty ? nil : $0 }
                        )
                    )

                    ScenarioTextRow(
                        label: "Sibling conflicts:",
                        text: Binding(
                            get: { viewModel.coRegulationAssessment.siblingConflictsStrategy ?? "" },
                            set: { viewModel.coRegulationAssessment.siblingConflictsStrategy = $0.isEmpty ? nil : $0 }
                        )
                    )

                    ScenarioTextRow(
                        label: "Unexpected changes:",
                        text: Binding(
                            get: { viewModel.coRegulationAssessment.unexpectedChangesStrategy ?? "" },
                            set: { viewModel.coRegulationAssessment.unexpectedChangesStrategy = $0.isEmpty ? nil : $0 }
                        )
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func questionSection<Content: View>(number: Int, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(number). \(title)")
                .font(.headline)
                .foregroundColor(.primary)

            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Toggle Actions

    private func togglePractice(_ practice: CoRegulationPractice) {
        if viewModel.coRegulationAssessment.currentPractices.contains(practice) {
            viewModel.coRegulationAssessment.currentPractices.removeAll { $0 == practice }
        } else {
            viewModel.coRegulationAssessment.currentPractices.append(practice)
        }
    }

    private func toggleSelfRegulation(_ strategy: ParentSelfRegulationStrategy) {
        if viewModel.coRegulationAssessment.parentSelfRegulation.contains(strategy) {
            viewModel.coRegulationAssessment.parentSelfRegulation.removeAll { $0 == strategy }
        } else {
            viewModel.coRegulationAssessment.parentSelfRegulation.append(strategy)
        }
    }

    private func togglePostRegulation(_ behavior: PostRegulationBehavior) {
        if viewModel.coRegulationAssessment.postRegulationConnection.contains(behavior) {
            viewModel.coRegulationAssessment.postRegulationConnection.removeAll { $0 == behavior }
        } else {
            viewModel.coRegulationAssessment.postRegulationConnection.append(behavior)
        }
    }

    private func toggleSupportNeed(_ need: SupportNeed) {
        if viewModel.coRegulationAssessment.supportNeeds.contains(need) {
            viewModel.coRegulationAssessment.supportNeeds.removeAll { $0 == need }
        } else {
            viewModel.coRegulationAssessment.supportNeeds.append(need)
        }
    }
}

// MARK: - Supporting Views

struct CheckboxRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                Text(label)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct RadioRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "circle.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                Text(label)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct RatingRow: View {
    let label: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .foregroundColor(value <= rating ? .yellow : .gray)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

struct ScenarioTextRow: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("What helps in this situation?", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }
}

#Preview {
    NavigationView {
        CoRegulationStepView(viewModel: ProfileCreationViewModel())
    }
}
