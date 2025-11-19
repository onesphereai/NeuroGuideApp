//
//  ModelTrainingViewModel.swift
//  NeuroGuide
//
//  ViewModel for model training UI
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ModelTrainingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isTraining = false
    @Published var trainingProgress: Double = 0.0
    @Published var currentPhase: TrainingPhase = .extractingFeatures
    @Published var errorMessage: String?
    @Published var trainingComplete = false
    @Published var trainedModel: CustomArousalModel?

    // MARK: - Private Properties

    private let trainingService = ModelTrainingService.shared
    private let trainingDataManager = TrainingDataManager.shared
    private let profileManager = ChildProfileManager.shared

    // MARK: - Computed Properties

    var progressPercentage: Int {
        Int(trainingProgress * 100)
    }

    var progressDescription: String {
        "\(currentPhase.displayName): \(progressPercentage)%"
    }

    var canStartTraining: Bool {
        guard let profile = profileManager.currentProfile else { return false }
        return trainingDataManager.isReadyToTrain && !isTraining
    }

    // MARK: - Public Methods

    /// Start training custom model
    func startTraining() async {
        guard let profile = profileManager.currentProfile else {
            errorMessage = "No child profile selected"
            return
        }

        guard let dataset = trainingDataManager.currentDataset else {
            errorMessage = "No training data available"
            return
        }

        isTraining = true
        errorMessage = nil
        trainingComplete = false
        trainedModel = nil
        trainingProgress = 0.0

        print("🚀 Starting model training...")

        do {
            let model = try await trainingService.trainModel(
                for: profile.id,
                videos: dataset.videos
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.trainingProgress = progress.progress
                    self?.currentPhase = progress.phase
                }
            }

            // Training complete
            trainedModel = model
            trainingComplete = true
            trainingProgress = 1.0

            print("✅ Training complete! Accuracy: \(String(format: "%.1f", (model.accuracy ?? 0) * 100))%")

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Training failed: \(error)")
        }

        isTraining = false
    }

    /// Reset training state
    func reset() {
        isTraining = false
        trainingProgress = 0.0
        currentPhase = .extractingFeatures
        errorMessage = nil
        trainingComplete = false
        trainedModel = nil
    }
}
