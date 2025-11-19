//
//  ModelTrainingService.swift
//  NeuroGuide
//
//  On-device ML model training service using k-NN classifier
//  NOTE: Uses k-Nearest Neighbors for iOS-compatible on-device training
//

import Foundation
import CoreML
import Accelerate

/// Service for training custom arousal detection models on-device
@MainActor
class ModelTrainingService {

    // MARK: - Singleton

    static let shared = ModelTrainingService()

    // MARK: - Private Properties

    private let featureExtractor = FeatureExtractorService.shared
    private let customModelManager = CustomModelManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Training

    /// Train a custom model from training videos
    /// Uses k-NN (k-Nearest Neighbors) algorithm for iOS-compatible on-device training
    func trainModel(
        for childID: UUID,
        videos: [TrainingVideo],
        progressCallback: ((TrainingProgress) -> Void)? = nil
    ) async throws -> CustomArousalModel {

        print("🧠 Starting model training for child: \(childID)")
        print("📊 Training data: \(videos.count) videos")
        print("🔬 Algorithm: k-Nearest Neighbors (k=5)")

        // Validate minimum requirements
        guard videos.count >= 25 else {
            throw ModelTrainingError.insufficientData(videos.count, required: 25)
        }

        // Validate balanced distribution across arousal states
        try validateDataDistribution(videos)

        // Phase 1: Feature Extraction (60% of progress)
        progressCallback?(TrainingProgress(phase: .extractingFeatures, progress: 0.0))

        let extractedFeatures = try await featureExtractor.extractFeatures(from: videos) { extractionProgress in
            let overallProgress = extractionProgress * 0.6  // 60% of total
            progressCallback?(TrainingProgress(phase: .extractingFeatures, progress: overallProgress))
        }

        print("✅ Feature extraction complete: \(extractedFeatures.count) feature sets")

        // Phase 2: Data Preparation (10% of progress)
        progressCallback?(TrainingProgress(phase: .preparingData, progress: 0.6))

        let (trainingData, validationData) = prepareTrainingData(from: extractedFeatures)

        print("✅ Data prepared - Training: \(trainingData.count), Validation: \(validationData.count)")

        // Phase 3: Model Training (20% of progress)
        // For k-NN, "training" just means storing the data and normalizing features
        progressCallback?(TrainingProgress(phase: .training, progress: 0.7))

        let knnModel = try buildKNNModel(from: trainingData)

        print("✅ k-NN model built with \(knnModel.trainingData.count) training examples")

        // Phase 4: Evaluation (5% of progress)
        progressCallback?(TrainingProgress(phase: .evaluating, progress: 0.9))

        let metrics = evaluateModel(knnModel, validationData: validationData)

        print("✅ Model evaluation complete")
        print("📈 Accuracy: \(String(format: "%.1f", metrics.accuracy * 100))%")
        print("📈 Precision: \(String(format: "%.1f", metrics.precision * 100))%")
        print("📈 Recall: \(String(format: "%.1f", metrics.recall * 100))%")

        // Phase 5: Export Model (5% of progress)
        progressCallback?(TrainingProgress(phase: .exporting, progress: 0.95))

        let modelURL = customModelManager.getModelStorageURL(for: childID, version: 1)
        try saveKNNModel(knnModel, to: modelURL)

        let modelSize = try FileManager.default.attributesOfItem(atPath: modelURL.path)[.size] as? Int64 ?? 0

        // Create model metadata
        let customModel = CustomArousalModel(
            id: UUID(),
            childID: childID,
            modelURL: modelURL,
            trainedAt: Date(),
            version: 1,
            accuracy: metrics.accuracy,
            trainingVideoCount: videos.count,
            modelSize: modelSize
        )

        // Save model metadata
        try await customModelManager.saveModel(customModel, for: childID)

        progressCallback?(TrainingProgress(phase: .complete, progress: 1.0))

        print("✅ Model training complete and saved!")

        return customModel
    }

    // MARK: - Private Methods

    private func validateDataDistribution(_ videos: [TrainingVideo]) throws {
        // Count videos per arousal state
        var stateCounts: [ArousalState: Int] = [:]
        for video in videos {
            stateCounts[video.arousalState, default: 0] += 1
        }

        // Verify each state has minimum 5 videos
        let minimumPerState = 5
        for state in ArousalState.allCases {
            let count = stateCounts[state] ?? 0
            if count < minimumPerState {
                throw ModelTrainingError.insufficientDataForState(state, count, required: minimumPerState)
            }
        }

        print("📊 Data distribution:")
        for state in ArousalState.allCases {
            print("   \(state.emoji) \(state.displayName): \(stateCounts[state] ?? 0) videos")
        }
    }

    private func prepareTrainingData(from features: [ExtractedFeatures]) -> (training: [TrainingExample], validation: [TrainingExample]) {
        // Convert features to training examples
        var examples: [TrainingExample] = []
        for feature in features {
            let dict = feature.toMLDictionary()

            // Extract feature vector (all numeric values except arousalState)
            var featureVector: [Double] = []
            let sortedKeys = dict.keys.filter { $0 != "arousalState" }.sorted()
            for key in sortedKeys {
                if let value = dict[key] as? Double {
                    featureVector.append(value)
                }
            }

            examples.append(TrainingExample(
                features: featureVector,
                label: feature.arousalState
            ))
        }

        // Shuffle
        let shuffled = examples.shuffled()

        // Split into training (80%) and validation (20%)
        let splitIndex = Int(Double(shuffled.count) * 0.8)
        let trainingData = Array(shuffled.prefix(splitIndex))
        let validationData = Array(shuffled.suffix(from: splitIndex))

        return (trainingData, validationData)
    }

    private func buildKNNModel(from trainingData: [TrainingExample]) throws -> KNNModel {
        guard !trainingData.isEmpty else {
            throw ModelTrainingError.trainingFailed(NSError(domain: "ModelTraining", code: -1, userInfo: [NSLocalizedDescriptionKey: "No training data"]))
        }

        // Calculate feature normalization parameters (mean and std for each feature)
        let featureDimension = trainingData[0].features.count
        var means = [Double](repeating: 0.0, count: featureDimension)
        var stds = [Double](repeating: 1.0, count: featureDimension)

        // Calculate means
        for example in trainingData {
            for (i, value) in example.features.enumerated() {
                means[i] += value
            }
        }
        for i in 0..<featureDimension {
            means[i] /= Double(trainingData.count)
        }

        // Calculate standard deviations
        for example in trainingData {
            for (i, value) in example.features.enumerated() {
                stds[i] += pow(value - means[i], 2)
            }
        }
        for i in 0..<featureDimension {
            stds[i] = sqrt(stds[i] / Double(trainingData.count))
            // Avoid division by zero
            if stds[i] < 0.0001 {
                stds[i] = 1.0
            }
        }

        // Normalize training data
        let normalizedData = trainingData.map { example -> TrainingExample in
            let normalizedFeatures = example.features.enumerated().map { (i, value) in
                (value - means[i]) / stds[i]
            }
            return TrainingExample(features: normalizedFeatures, label: example.label)
        }

        return KNNModel(
            trainingData: normalizedData,
            featureMeans: means,
            featureStds: stds,
            k: 5  // k=5 is a good default for small datasets
        )
    }

    private func evaluateModel(_ model: KNNModel, validationData: [TrainingExample]) -> ModelMetrics {
        var correct = 0
        var total = 0
        var truePositives: [ArousalState: Int] = [:]
        var falsePositives: [ArousalState: Int] = [:]
        var falseNegatives: [ArousalState: Int] = [:]

        for example in validationData {
            let predicted = model.predict(features: example.features)
            let actual = example.label

            total += 1
            if actual == predicted {
                correct += 1
                truePositives[actual, default: 0] += 1
            } else {
                falseNegatives[actual, default: 0] += 1
                falsePositives[predicted, default: 0] += 1
            }
        }

        let accuracy = total > 0 ? Double(correct) / Double(total) : 0.0

        // Calculate average precision and recall
        var precisions: [Double] = []
        var recalls: [Double] = []

        for state in ArousalState.allCases {
            let tp = truePositives[state] ?? 0
            let fp = falsePositives[state] ?? 0
            let fn = falseNegatives[state] ?? 0

            let precision = (tp + fp) > 0 ? Double(tp) / Double(tp + fp) : 0.0
            let recall = (tp + fn) > 0 ? Double(tp) / Double(tp + fn) : 0.0

            precisions.append(precision)
            recalls.append(recall)
        }

        let avgPrecision = precisions.reduce(0.0, +) / Double(precisions.count)
        let avgRecall = recalls.reduce(0.0, +) / Double(recalls.count)

        return ModelMetrics(
            accuracy: accuracy,
            precision: avgPrecision,
            recall: avgRecall,
            confusionMatrix: [:]
        )
    }

    private func saveKNNModel(_ model: KNNModel, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(model)
        try data.write(to: url)
        print("✅ Model saved to: \(url.path)")
    }
}

// MARK: - k-NN Model

/// k-Nearest Neighbors classifier model
struct KNNModel: Codable {
    let trainingData: [TrainingExample]
    let featureMeans: [Double]
    let featureStds: [Double]
    let k: Int

    var featureDimension: Int {
        return featureMeans.count
    }

    /// Predict arousal state for given features
    func predict(features: [Double]) -> ArousalState {
        // Normalize input features
        let normalizedFeatures = features.enumerated().map { (i, value) in
            (value - featureMeans[i]) / featureStds[i]
        }

        // Calculate distances to all training examples
        var distances: [(distance: Double, label: ArousalState)] = []
        for example in trainingData {
            let distance = euclideanDistance(normalizedFeatures, example.features)
            distances.append((distance, example.label))
        }

        // Sort by distance and take k nearest
        distances.sort { $0.distance < $1.distance }
        let kNearest = distances.prefix(k)

        // Vote: count labels among k nearest neighbors
        var votes: [ArousalState: Int] = [:]
        for (_, label) in kNearest {
            votes[label, default: 0] += 1
        }

        // Return label with most votes
        let winner = votes.max { $0.value < $1.value }
        return winner?.key ?? .calm  // Default to calm if no votes
    }

    private func euclideanDistance(_ a: [Double], _ b: [Double]) -> Double {
        var sum = 0.0
        for i in 0..<min(a.count, b.count) {
            sum += pow(a[i] - b[i], 2)
        }
        return sqrt(sum)
    }
}

/// Single training example
struct TrainingExample: Codable {
    let features: [Double]
    let label: ArousalState
}

// MARK: - Training Progress

struct TrainingProgress {
    let phase: TrainingPhase
    let progress: Double  // 0.0 to 1.0

    var percentage: Int {
        Int(progress * 100)
    }

    var description: String {
        "\(phase.displayName): \(percentage)%"
    }
}

enum TrainingPhase {
    case extractingFeatures
    case preparingData
    case training
    case evaluating
    case exporting
    case complete

    var displayName: String {
        switch self {
        case .extractingFeatures:
            return "Extracting Features"
        case .preparingData:
            return "Preparing Data"
        case .training:
            return "Training Model"
        case .evaluating:
            return "Evaluating Model"
        case .exporting:
            return "Exporting Model"
        case .complete:
            return "Complete"
        }
    }
}

// MARK: - Model Metrics

struct ModelMetrics {
    let accuracy: Double
    let precision: Double
    let recall: Double
    let confusionMatrix: [String: [String: Int]]

    var f1Score: Double {
        guard (precision + recall) > 0 else { return 0.0 }
        return 2 * (precision * recall) / (precision + recall)
    }
}

// MARK: - Errors

enum ModelTrainingError: LocalizedError {
    case insufficientData(Int, required: Int)
    case insufficientDataForState(ArousalState, Int, required: Int)
    case trainingFailed(Error)
    case evaluationFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .insufficientData(let count, let required):
            return "Insufficient training data: \(count) videos (minimum \(required) required)"
        case .insufficientDataForState(let state, let count, let required):
            return "Insufficient data for \(state.displayName): \(count) videos (minimum \(required) required per state)"
        case .trainingFailed(let error):
            return "Model training failed: \(error.localizedDescription)"
        case .evaluationFailed:
            return "Model evaluation failed"
        case .exportFailed:
            return "Failed to export trained model"
        }
    }
}
