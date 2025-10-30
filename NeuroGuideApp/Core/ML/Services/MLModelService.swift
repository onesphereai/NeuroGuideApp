//
//  MLModelService.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import CoreML

/// Protocol for managing ML model lifecycle and inference
protocol MLModelService {

    /// Load a model of the specified type
    /// - Parameter type: The type of model to load
    /// - Returns: Loaded MLModel instance
    /// - Throws: MLModelError if loading fails
    func loadModel(type: MLModelType) async throws -> MLModel

    /// Run inference on a loaded model
    /// - Parameters:
    ///   - type: The type of model to run inference on
    ///   - input: Input features for the model
    /// - Returns: Model output as MLFeatureProvider
    /// - Throws: MLModelError if inference fails
    func runInference(type: MLModelType, input: MLFeatureProvider) async throws -> MLFeatureProvider

    /// Unload a model to free memory
    /// - Parameter type: The type of model to unload
    func unloadModel(type: MLModelType)

    /// Unload all models
    func unloadAllModels()

    /// Preload multiple models
    /// - Parameter types: Array of model types to preload
    func preloadModels(_ types: [MLModelType]) async

    /// Check if a model is currently loaded
    /// - Parameter type: The type of model to check
    /// - Returns: True if the model is loaded
    func isModelLoaded(type: MLModelType) -> Bool

    /// Get performance metrics for a model
    /// - Parameter type: The type of model
    /// - Returns: Most recent performance metrics, or nil if not available
    func getPerformanceMetrics(for type: MLModelType) -> ModelPerformanceMetrics?

    /// Get model configuration
    /// - Parameter type: The type of model
    /// - Returns: MLModelConfiguration for the model
    func getModelConfiguration(for type: MLModelType) -> MLModelConfiguration
}

/// Errors that can occur during ML model operations
enum MLModelError: LocalizedError {
    case modelNotFound(MLModelType)
    case modelLoadFailed(MLModelType, underlying: Error)
    case modelNotLoaded(MLModelType)
    case inferenceFailed(MLModelType, underlying: Error)
    case invalidInput(MLModelType, reason: String)
    case insufficientMemory
    case modelNotAvailable(MLModelType)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let type):
            return "Model not found: \(type.displayName)"
        case .modelLoadFailed(let type, let error):
            return "Failed to load \(type.displayName): \(error.localizedDescription)"
        case .modelNotLoaded(let type):
            return "Model not loaded: \(type.displayName)"
        case .inferenceFailed(let type, let error):
            return "Inference failed for \(type.displayName): \(error.localizedDescription)"
        case .invalidInput(let type, let reason):
            return "Invalid input for \(type.displayName): \(reason)"
        case .insufficientMemory:
            return "Insufficient memory to load model"
        case .modelNotAvailable(let type):
            return "Model not yet available: \(type.displayName). Will be implemented in future bolts."
        }
    }
}
