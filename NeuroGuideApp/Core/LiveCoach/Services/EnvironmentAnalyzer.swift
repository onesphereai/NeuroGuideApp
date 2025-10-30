//
//  EnvironmentAnalyzer.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach: Environmental Context Detection
//

import Foundation
import Vision
import CoreImage
import AVFoundation

/// Analyzes environmental context (lighting, visual complexity, crowd density)
class EnvironmentAnalyzer {

    // MARK: - Properties

    private var brightnessHistory: [Float] = []
    private let maxHistorySize = 10  // ~0.3 seconds at 30fps

    // MARK: - Main Analysis

    /// Analyze complete environment context from video frame
    func analyzeEnvironment(from pixelBuffer: CVPixelBuffer, noiseLevel: NoiseLevel) async throws -> EnvironmentContext {
        // Analyze lighting
        let lightingLevel = await analyzeLighting(from: pixelBuffer)

        // Analyze visual complexity
        let visualComplexity = await analyzeVisualComplexity(from: pixelBuffer)

        // Analyze crowd density
        let crowdDensity = await analyzeCrowdDensity(from: pixelBuffer)

        return EnvironmentContext(
            lightingLevel: lightingLevel,
            visualComplexity: visualComplexity,
            noiseLevel: noiseLevel,
            noiseType: nil,  // Can be filled by AudioAnalyzer
            crowdDensity: crowdDensity,
            timestamp: Date()
        )
    }

    // MARK: - Lighting Analysis

    /// Analyze lighting level from frame
    private func analyzeLighting(from pixelBuffer: CVPixelBuffer) async -> LightingLevel {
        // Method 1: Use Vision framework to detect brightness
        let brightness = await detectBrightness(from: pixelBuffer)

        // Add to history for flicker detection
        brightnessHistory.append(brightness)
        if brightnessHistory.count > maxHistorySize {
            brightnessHistory.removeFirst()
        }

        // Check for flickering
        if detectFlickering() {
            return .flickering
        }

        // Classify brightness level
        switch brightness {
        case 0..<0.3:
            return .dim
        case 0.3..<0.7:
            return .normal
        default:
            return .bright
        }
    }

    /// Detect brightness using Vision framework
    private func detectBrightness(from pixelBuffer: CVPixelBuffer) async -> Float {
        // Create CIImage from pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Calculate average brightness
        let extent = ciImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: inputExtent]) else {
            return 0.5  // Default to normal
        }

        guard let outputImage = filter.outputImage else {
            return 0.5
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])

        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        // Calculate luminance from RGB
        let red = Float(bitmap[0]) / 255.0
        let green = Float(bitmap[1]) / 255.0
        let blue = Float(bitmap[2]) / 255.0

        // Use standard luminance formula
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

        return luminance
    }

    /// Detect flickering lights
    private func detectFlickering() -> Bool {
        guard brightnessHistory.count >= 6 else { return false }

        // Calculate variance in brightness
        let mean = brightnessHistory.reduce(0, +) / Float(brightnessHistory.count)

        var variance: Float = 0
        for brightness in brightnessHistory {
            let diff = brightness - mean
            variance += diff * diff
        }
        variance /= Float(brightnessHistory.count)

        let stdDev = sqrt(variance)

        // High variance indicates flickering
        // Threshold: std dev > 0.15 (15% variation)
        return stdDev > 0.15
    }

    // MARK: - Visual Complexity Analysis

    /// Analyze visual complexity using saliency detection
    private func analyzeVisualComplexity(from pixelBuffer: CVPixelBuffer) async -> VisualComplexity {
        do {
            let request = VNGenerateAttentionBasedSaliencyImageRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            try handler.perform([request])

            guard let observation = request.results?.first else {
                return .moderate
            }

            // Count salient objects/regions
            let salientObjects = observation.salientObjects?.count ?? 0

            // Classify based on object count only
            // Note: Pixel buffer density analysis removed due to Vision API limitations
            switch salientObjects {
            case 0...3:
                return .calm
            case 4...7:
                return .moderate
            default:
                return .cluttered
            }
        } catch {
            // On error, assume moderate complexity
            return .moderate
        }
    }

    /// Calculate overall saliency density from saliency map
    private func calculateSaliencyDensity(_ pixelBuffer: CVPixelBuffer) -> Float {
        // Lock pixel buffer for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0.5
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Sample pixels and calculate average saliency
        var totalSaliency: Float = 0
        var sampleCount = 0

        // Sample every 10th pixel to reduce computation
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = y * bytesPerRow + x
                let saliencyValue = buffer[offset]
                totalSaliency += Float(saliencyValue) / 255.0
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return 0.5 }

        return totalSaliency / Float(sampleCount)
    }

    // MARK: - Crowd Density Analysis

    /// Detect number of people in frame
    private func analyzeCrowdDensity(from pixelBuffer: CVPixelBuffer) async -> CrowdDensity? {
        do {
            let request = VNDetectHumanRectanglesRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            try handler.perform([request])

            guard let results = request.results else {
                return nil
            }

            let personCount = results.count

            // Classify crowd density
            switch personCount {
            case 0...1:
                return .solo
            case 2...4:
                return .fewPeople
            default:
                return .crowded
            }
        } catch {
            // On error, return nil (unknown)
            return nil
        }
    }

    /// Clear brightness history
    func clearHistory() {
        brightnessHistory.removeAll()
    }
}
