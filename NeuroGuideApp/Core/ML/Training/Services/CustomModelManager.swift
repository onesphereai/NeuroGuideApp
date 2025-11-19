//
//  CustomModelManager.swift
//  NeuroGuide
//
//  Manages custom trained ML models for personalized arousal detection
//

import Foundation
import CoreML
import Combine

/// Manages custom ML models trained per child
@MainActor
class CustomModelManager: ObservableObject {

    // MARK: - Singleton

    static let shared = CustomModelManager()

    // MARK: - Published Properties

    @Published private(set) var currentModel: CustomArousalModel?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private let secureStorage: SecureStorageService
    private let modelsDirectoryName = "CustomModels"

    // Storage keys
    private let modelMetadataKey = "custom.model.metadata"

    // MARK: - Initialization

    private init(secureStorage: SecureStorageService = SecureStorageManager.shared) {
        self.secureStorage = secureStorage
        createModelsDirectoryIfNeeded()
    }

    // MARK: - Model Availability

    /// Check if a custom model exists for a child
    func hasCustomModel(for childID: UUID) async -> Bool {
        do {
            let metadata = try await loadModelMetadata(for: childID)
            return metadata != nil && fileManager.fileExists(atPath: metadata!.modelURL.path)
        } catch {
            return false
        }
    }

    /// Get custom model for a child (if available)
    func getCustomModel(for childID: UUID) async throws -> CustomArousalModel? {
        guard let metadata = try await loadModelMetadata(for: childID) else {
            return nil
        }

        // Verify model file exists
        guard fileManager.fileExists(atPath: metadata.modelURL.path) else {
            print("⚠️ Model metadata exists but file is missing: \(metadata.modelURL.path)")
            return nil
        }

        return metadata
    }

    /// Load CoreML model for inference (legacy - not used for k-NN)
    func loadMLModel(for childID: UUID) async throws -> MLModel? {
        guard let metadata = try await getCustomModel(for: childID) else {
            throw CustomModelError.modelNotFound
        }

        do {
            let model = try MLModel(contentsOf: metadata.modelURL)
            print("✅ Loaded custom ML model for child \(childID)")
            return model
        } catch {
            print("❌ Failed to load ML model: \(error)")
            throw CustomModelError.modelLoadFailed(error)
        }
    }

    /// Load k-NN model for inference
    func loadKNNModel(for childID: UUID) async throws -> KNNModel {
        guard let metadata = try await getCustomModel(for: childID) else {
            throw CustomModelError.modelNotFound
        }

        do {
            let data = try Data(contentsOf: metadata.modelURL)
            let decoder = JSONDecoder()
            let model = try decoder.decode(KNNModel.self, from: data)
            print("✅ Loaded k-NN model for child \(childID)")
            return model
        } catch {
            print("❌ Failed to load k-NN model: \(error)")
            throw CustomModelError.modelLoadFailed(error)
        }
    }

    // MARK: - Model Management

    /// Save custom model metadata
    func saveModel(
        _ metadata: CustomArousalModel,
        for childID: UUID
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let key = "\(modelMetadataKey).\(childID.uuidString)"
        try await secureStorage.save(metadata, forKey: key)

        currentModel = metadata
        print("✅ Saved custom model metadata for child \(childID)")
    }

    /// Delete custom model for a child
    func deleteModel(for childID: UUID) async throws {
        guard let metadata = try await getCustomModel(for: childID) else {
            return  // No model to delete
        }

        // Delete model file
        try? fileManager.removeItem(at: metadata.modelURL)

        // Delete metadata
        let key = "\(modelMetadataKey).\(childID.uuidString)"
        try await secureStorage.delete(forKey: key)

        if currentModel?.childID == childID {
            currentModel = nil
        }

        print("✅ Deleted custom model for child \(childID)")
    }

    /// Get all children with custom models
    func getChildrenWithModels() async throws -> [UUID] {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsURL = documentsURL.appendingPathComponent(modelsDirectoryName)

        guard fileManager.fileExists(atPath: modelsURL.path) else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: modelsURL,
                includingPropertiesForKeys: [.isDirectoryKey]
            )

            // Filter for directories (child IDs)
            let childIDs = contents.compactMap { url -> UUID? in
                guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                      resourceValues.isDirectory == true else {
                    return nil
                }
                return UUID(uuidString: url.lastPathComponent)
            }

            return childIDs
        } catch {
            print("⚠️ Failed to list model directories: \(error)")
            return []
        }
    }

    // MARK: - Private Methods

    private func loadModelMetadata(for childID: UUID) async throws -> CustomArousalModel? {
        let key = "\(modelMetadataKey).\(childID.uuidString)"
        return try await secureStorage.load(forKey: key, as: CustomArousalModel.self)
    }

    private func createModelsDirectoryIfNeeded() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsURL = documentsURL.appendingPathComponent(modelsDirectoryName)

        if !fileManager.fileExists(atPath: modelsURL.path) {
            try? fileManager.createDirectory(at: modelsURL, withIntermediateDirectories: true)
            print("📁 Created custom models directory")
        }
    }

    /// Get model storage URL for a child
    func getModelStorageURL(for childID: UUID, version: Int) -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsURL = documentsURL.appendingPathComponent(modelsDirectoryName)
        let childModelsURL = modelsURL.appendingPathComponent(childID.uuidString)

        // Create child directory if needed
        if !fileManager.fileExists(atPath: childModelsURL.path) {
            try? fileManager.createDirectory(at: childModelsURL, withIntermediateDirectories: true)
        }

        return childModelsURL.appendingPathComponent("arousal_model_v\(version).mlmodelc")
    }

    // MARK: - Model Statistics

    /// Get total number of custom models
    func getTotalModelCount() async -> Int {
        do {
            let childIDs = try await getChildrenWithModels()
            return childIDs.count
        } catch {
            return 0
        }
    }

    /// Get total storage used by custom models
    func getTotalStorageUsed() async -> Int64 {
        do {
            let childIDs = try await getChildrenWithModels()
            var totalSize: Int64 = 0

            for childID in childIDs {
                if let metadata = try await getCustomModel(for: childID) {
                    totalSize += metadata.modelSize
                }
            }

            return totalSize
        } catch {
            return 0
        }
    }
}

// MARK: - Errors

enum CustomModelError: LocalizedError {
    case modelNotFound
    case modelLoadFailed(Error)
    case invalidModelFormat
    case trainingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Custom model not found for this child"
        case .modelLoadFailed(let error):
            return "Failed to load custom model: \(error.localizedDescription)"
        case .invalidModelFormat:
            return "Model file is corrupted or invalid"
        case .trainingFailed(let error):
            return "Model training failed: \(error.localizedDescription)"
        }
    }
}
