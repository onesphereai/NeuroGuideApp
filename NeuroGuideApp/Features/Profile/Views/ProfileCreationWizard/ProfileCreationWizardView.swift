//
//  ProfileCreationWizardView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Unit 3 - Child Profile & Personalization (Bolt 3.1)
//

import SwiftUI

/// Multi-step wizard for creating a child profile
struct ProfileCreationWizardView: View {
    @StateObject private var viewModel: ProfileCreationViewModel
    @Environment(\.dismiss) private var dismiss

    init(existingProfile: ChildProfile? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileCreationViewModel(existingProfile: existingProfile))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityLabel("Progress: \(Int(viewModel.progress * 100))%")

                // Current step title and description
                VStack(spacing: 8) {
                    Text(viewModel.currentStep.title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(viewModel.currentStep.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    BasicInfoStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.basicInfo)

                    DiagnosisStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.diagnosis)

                    CommunicationStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.communication)

                    TriggersStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.triggers)

                    CoRegulationStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.coRegulation)

                    SensoryPreferencesStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.sensoryPreferences)

                    CalibrationStepView(viewModel: viewModel)
                        .tag(ProfileCreationStep.calibration)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                HStack(spacing: 16) {
                    if viewModel.canGoBack {
                        Button {
                            viewModel.goBack()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    Button {
                        Task {
                            await viewModel.goNext()
                        }
                    } label: {
                        HStack {
                            Text(viewModel.nextButtonTitle)
                            if viewModel.currentStep != .calibration {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canGoNext)
                }
                .padding()
            }
            .navigationTitle(viewModel.wizardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .onChange(of: viewModel.isComplete) { isComplete in
                if isComplete {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

struct ProfileCreationWizardView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCreationWizardView()
    }
}
