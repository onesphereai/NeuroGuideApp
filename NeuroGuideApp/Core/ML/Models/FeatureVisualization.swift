//
//  FeatureVisualization.swift
//  NeuroGuide
//
//  Model for visualizing what the ML model is detecting in real-time
//

import Foundation

/// Real-time feature data for transparency/debugging
struct FeatureVisualization: Codable, Equatable {
    // Pose features
    let poseAvailable: Bool
    let movementIntensity: Double?      // 0-1
    let bodyTension: Double?            // 0-1
    let postureOpenness: Double?        // 0-1
    let poseConfidence: Double?         // 0-1

    // Facial features
    let facialAvailable: Bool
    let expressionIntensity: Double?    // 0-1
    let mouthOpenness: Double?          // 0-1
    let eyeWideness: Double?            // 0-1
    let browRaised: Bool?
    let facialConfidence: Double?       // 0-1

    // Vocal features
    let vocalAvailable: Bool
    let volume: Double?                 // 0-1
    let pitch: Double?                  // Hz
    let energy: Double?                 // 0-1
    let speechRate: Double?             // 0-1

    // Classification result
    let predictedBand: ArousalBand
    let overallConfidence: Double       // 0-1
    let usingCustomModel: Bool          // Whether k-NN model is active

    static let empty = FeatureVisualization(
        poseAvailable: false,
        movementIntensity: nil,
        bodyTension: nil,
        postureOpenness: nil,
        poseConfidence: nil,
        facialAvailable: false,
        expressionIntensity: nil,
        mouthOpenness: nil,
        eyeWideness: nil,
        browRaised: nil,
        facialConfidence: nil,
        vocalAvailable: false,
        volume: nil,
        pitch: nil,
        energy: nil,
        speechRate: nil,
        predictedBand: .green,
        overallConfidence: 0.0,
        usingCustomModel: false
    )
}
