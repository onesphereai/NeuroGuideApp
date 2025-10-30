//
//  MLModelManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import CoreML
import Combine

/// Implementation of MLModelService
class MLModelManager: MLModelService {

    // MARK: - Singleton

    static let shared = MLModelManager()

    // MARK: - Private Properties

    private var loadedModels: [MLModelType: MLModel] = [:]
    private var modelLock = NSLock()
    private var performanceMetrics: [MLModelType: ModelPerformanceMetrics] = [:]
    private let deviceCapability: DeviceCapabilityService

    // MARK: - Initialization

    private init(deviceCapability: DeviceCapabilityService = DeviceCapabilityManager.shared) {
        self.deviceCapability = deviceCapability
    }

    // MARK: - Public Methods

    func loadModel(type: MLModelType) async throws -> MLModel {
        modelLock.lock()
        defer { modelLock.unlock() }

        // Return cached model if already loaded
        if let existingModel = loadedModels[type] {
            return existingModel
        }

        // Check if model is available
        guard type.isAvailable else {
            throw MLModelError.modelNotAvailable(type)
        }

        // Check memory availability
        let availableMemory = deviceCapability.getAvailableMemory()
        let requirements = getRequirements(for: type)
        guard availableMemory >= requirements.minimumMemoryBytes else {
            throw MLModelError.insufficientMemory
        }

        // Load the model
        do {
            let startTime = Date()
            let model = try await loadModelFromBundle(type: type)
            let loadTime = Date().timeIntervalSince(startTime)

            print("✅ Loaded \(type.displayName) in \(String(format: "%.2f", loadTime * 1000))ms")

            loadedModels[type] = model
            return model

        } catch {
            throw MLModelError.modelLoadFailed(type, underlying: error)
        }
    }

    func runInference(type: MLModelType, input: MLFeatureProvider) async throws -> MLFeatureProvider {
        // Ensure model is loaded
        let model: MLModel
        if let loaded = loadedModels[type] {
            model = loaded
        } else {
            model = try await loadModel(type: type)
        }

        // Run inference and track performance
        let startTime = Date()
        let startMemory = getMemoryUsage()

        do {
            let output = try await model.prediction(from: input)
            let inferenceTime = Date().timeIntervalSince(startTime)
            let endMemory = getMemoryUsage()
            let memoryDelta = max(0, endMemory - startMemory)

            // Record performance metrics
            let metrics = ModelPerformanceMetrics(
                modelType: type,
                inferenceLatency: inferenceTime,
                memoryUsage: memoryDelta,
                batteryImpact: estimateBatteryImpact(inferenceTime: inferenceTime),
                timestamp: Date()
            )

            performanceMetrics[type] = metrics

            // Log performance
            if !metrics.meetsLatencyTarget {
                print("⚠️ \(type.displayName) latency: \(String(format: "%.1f", metrics.latencyMs))ms (target: \(String(format: "%.1f", type.latencyTarget * 1000))ms)")
            }

            return output

        } catch {
            throw MLModelError.inferenceFailed(type, underlying: error)
        }
    }

    func unloadModel(type: MLModelType) {
        modelLock.lock()
        defer { modelLock.unlock() }

        if loadedModels.removeValue(forKey: type) != nil {
            print("🗑️ Unloaded \(type.displayName)")
        }
    }

    func unloadAllModels() {
        modelLock.lock()
        defer { modelLock.unlock() }

        let count = loadedModels.count
        loadedModels.removeAll()
        print("🗑️ Unloaded all \(count) models")
    }

    func preloadModels(_ types: [MLModelType]) async {
        for type in types {
            do {
                _ = try await loadModel(type: type)
            } catch {
                print("❌ Failed to preload \(type.displayName): \(error.localizedDescription)")
            }
        }
    }

    func isModelLoaded(type: MLModelType) -> Bool {
        modelLock.lock()
        defer { modelLock.unlock() }
        return loadedModels[type] != nil
    }

    func getPerformanceMetrics(for type: MLModelType) -> ModelPerformanceMetrics? {
        return performanceMetrics[type]
    }

    func getModelConfiguration(for type: MLModelType) -> MLModelConfiguration {
        let config = MLModelConfiguration()

        // Use Neural Engine if available
        if deviceCapability.supportsNeuralEngine() {
            config.computeUnits = .all
        } else {
            // Fallback to GPU/CPU
            config.computeUnits = .cpuAndGPU
        }

        // Allow background execution
        config.allowLowPrecisionAccumulationOnGPU = true

        return config
    }

    // MARK: - Private Methods

    private func loadModelFromBundle(type: MLModelType) async throws -> MLModel {
        // Get model URL from bundle
        guard let modelURL = getModelURL(for: type) else {
            throw MLModelError.modelNotFound(type)
        }

        // Get configuration
        let config = getModelConfiguration(for: type)

        // Load model
        let compiledURL = try await MLModel.compileModel(at: modelURL)
        let model = try await MLModel.load(contentsOf: compiledURL, configuration: config)

        return model
    }

    private func getModelURL(for type: MLModelType) -> URL? {
        // Look for model in bundle
        let modelName = type.modelFileName

        // Try .mlmodelc (compiled) first
        if let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
            return url
        }

        // Try .mlpackage
        if let url = Bundle.main.url(forResource: modelName, withExtension: "mlpackage") {
            return url
        }

        // Try .mlmodel
        if let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
            return url
        }

        return nil
    }

    private func getRequirements(for type: MLModelType) -> ModelRequirements {
        switch type {
        case .poseDetection:
            return .poseDetection
        case .vocalAffect:
            return .vocalAffect
        case .facialExpression:
            return .facialExpression
        case .parentStress:
            return .parentStress
        case .test:
            return .test
        }
    }

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    private func estimateBatteryImpact(inferenceTime: TimeInterval) -> Double {
        // Rough estimation:
        // - Neural Engine: ~0.01% per 100ms
        // - GPU: ~0.02% per 100ms
        // - CPU: ~0.03% per 100ms
        let baseImpact = deviceCapability.supportsNeuralEngine() ? 0.01 : 0.02
        return (inferenceTime / 0.1) * baseImpact
    }
}
