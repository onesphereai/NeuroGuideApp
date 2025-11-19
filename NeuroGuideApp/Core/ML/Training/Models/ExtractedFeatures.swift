//
//  ExtractedFeatures.swift
//  NeuroGuide
//
//  Feature representations extracted from training videos
//

import Foundation
import CoreML

/// Complete feature set extracted from a single training video
struct ExtractedFeatures: Codable {
    let videoID: UUID
    let childID: UUID
    let arousalState: ArousalState
    let extractedAt: Date

    // Feature vectors
    let poseFeatures: PoseFeatureVector
    let facialFeatures: FacialFeatureVector
    let audioFeatures: AudioFeatureVector

    /// Convert to dictionary for Create ML (will be used with MLDataTable)
    func toMLDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        // Add arousal state as target
        dict["arousalState"] = arousalState.rawValue

        // Add all pose features
        for (key, value) in poseFeatures.toDictionary() {
            dict[key] = value
        }

        // Add all facial features
        for (key, value) in facialFeatures.toDictionary() {
            dict[key] = value
        }

        // Add all audio features
        for (key, value) in audioFeatures.toDictionary() {
            dict[key] = value
        }

        return dict
    }
}

// MARK: - Pose Feature Vector

/// Aggregated pose features from video
struct PoseFeatureVector: Codable {
    // Head position (normalized 0-1)
    let headX_mean: Double
    let headX_std: Double
    let headY_mean: Double
    let headY_std: Double

    // Torso movement
    let torsoX_mean: Double
    let torsoX_std: Double
    let torsoY_mean: Double
    let torsoY_std: Double

    // Arm movement (left and right)
    let leftArmX_mean: Double
    let leftArmX_std: Double
    let leftArmY_mean: Double
    let leftArmY_std: Double
    let rightArmX_mean: Double
    let rightArmX_std: Double
    let rightArmY_mean: Double
    let rightArmY_std: Double

    // Leg movement
    let leftLegX_mean: Double
    let leftLegX_std: Double
    let leftLegY_mean: Double
    let leftLegY_std: Double
    let rightLegX_mean: Double
    let rightLegX_std: Double
    let rightLegY_mean: Double
    let rightLegY_std: Double

    // Velocity features (movement speed)
    let overallVelocity_mean: Double
    let overallVelocity_std: Double
    let overallVelocity_max: Double

    // Body openness (distance between limbs)
    let bodyOpenness_mean: Double
    let bodyOpenness_std: Double

    // Posture angle
    let postureAngle_mean: Double
    let postureAngle_std: Double

    func toDictionary() -> [String: Double] {
        return [
            "pose_headX_mean": headX_mean,
            "pose_headX_std": headX_std,
            "pose_headY_mean": headY_mean,
            "pose_headY_std": headY_std,
            "pose_torsoX_mean": torsoX_mean,
            "pose_torsoX_std": torsoX_std,
            "pose_torsoY_mean": torsoY_mean,
            "pose_torsoY_std": torsoY_std,
            "pose_leftArmX_mean": leftArmX_mean,
            "pose_leftArmX_std": leftArmX_std,
            "pose_leftArmY_mean": leftArmY_mean,
            "pose_leftArmY_std": leftArmY_std,
            "pose_rightArmX_mean": rightArmX_mean,
            "pose_rightArmX_std": rightArmX_std,
            "pose_rightArmY_mean": rightArmY_mean,
            "pose_rightArmY_std": rightArmY_std,
            "pose_leftLegX_mean": leftLegX_mean,
            "pose_leftLegX_std": leftLegX_std,
            "pose_leftLegY_mean": leftLegY_mean,
            "pose_leftLegY_std": leftLegY_std,
            "pose_rightLegX_mean": rightLegX_mean,
            "pose_rightLegX_std": rightLegX_std,
            "pose_rightLegY_mean": rightLegY_mean,
            "pose_rightLegY_std": rightLegY_std,
            "pose_velocity_mean": overallVelocity_mean,
            "pose_velocity_std": overallVelocity_std,
            "pose_velocity_max": overallVelocity_max,
            "pose_openness_mean": bodyOpenness_mean,
            "pose_openness_std": bodyOpenness_std,
            "pose_angle_mean": postureAngle_mean,
            "pose_angle_std": postureAngle_std
        ]
    }
}

// MARK: - Facial Feature Vector

/// Aggregated facial features from video
struct FacialFeatureVector: Codable {
    // Facial landmarks - key points (normalized 0-1)
    // Eyes
    let leftEyeOpenness_mean: Double
    let leftEyeOpenness_std: Double
    let rightEyeOpenness_mean: Double
    let rightEyeOpenness_std: Double

    // Mouth
    let mouthOpenness_mean: Double
    let mouthOpenness_std: Double
    let mouthWidth_mean: Double
    let mouthWidth_std: Double

    // Eyebrows
    let leftBrowHeight_mean: Double
    let leftBrowHeight_std: Double
    let rightBrowHeight_mean: Double
    let rightBrowHeight_std: Double

    // Face action units (0-1 intensity)
    let browRaiser_mean: Double
    let browRaiser_std: Double
    let browLowerer_mean: Double
    let browLowerer_std: Double
    let lipCornerPuller_mean: Double  // smile
    let lipCornerPuller_std: Double
    let jawDrop_mean: Double
    let jawDrop_std: Double
    let cheekRaiser_mean: Double
    let cheekRaiser_std: Double

    // Head pose
    let headYaw_mean: Double  // left-right rotation
    let headYaw_std: Double
    let headPitch_mean: Double  // up-down rotation
    let headPitch_std: Double
    let headRoll_mean: Double  // tilt
    let headRoll_std: Double

    func toDictionary() -> [String: Double] {
        return [
            "face_leftEyeOpen_mean": leftEyeOpenness_mean,
            "face_leftEyeOpen_std": leftEyeOpenness_std,
            "face_rightEyeOpen_mean": rightEyeOpenness_mean,
            "face_rightEyeOpen_std": rightEyeOpenness_std,
            "face_mouthOpen_mean": mouthOpenness_mean,
            "face_mouthOpen_std": mouthOpenness_std,
            "face_mouthWidth_mean": mouthWidth_mean,
            "face_mouthWidth_std": mouthWidth_std,
            "face_leftBrow_mean": leftBrowHeight_mean,
            "face_leftBrow_std": leftBrowHeight_std,
            "face_rightBrow_mean": rightBrowHeight_mean,
            "face_rightBrow_std": rightBrowHeight_std,
            "face_browRaise_mean": browRaiser_mean,
            "face_browRaise_std": browRaiser_std,
            "face_browLower_mean": browLowerer_mean,
            "face_browLower_std": browLowerer_std,
            "face_smile_mean": lipCornerPuller_mean,
            "face_smile_std": lipCornerPuller_std,
            "face_jaw_mean": jawDrop_mean,
            "face_jaw_std": jawDrop_std,
            "face_cheek_mean": cheekRaiser_mean,
            "face_cheek_std": cheekRaiser_std,
            "face_yaw_mean": headYaw_mean,
            "face_yaw_std": headYaw_std,
            "face_pitch_mean": headPitch_mean,
            "face_pitch_std": headPitch_std,
            "face_roll_mean": headRoll_mean,
            "face_roll_std": headRoll_std
        ]
    }
}

// MARK: - Audio Feature Vector

/// Aggregated audio features from video
struct AudioFeatureVector: Codable {
    // MFCC coefficients (mel-frequency cepstral coefficients)
    let mfcc0_mean: Double
    let mfcc0_std: Double
    let mfcc1_mean: Double
    let mfcc1_std: Double
    let mfcc2_mean: Double
    let mfcc2_std: Double
    let mfcc3_mean: Double
    let mfcc3_std: Double
    let mfcc4_mean: Double
    let mfcc4_std: Double
    let mfcc5_mean: Double
    let mfcc5_std: Double

    // Pitch features
    let pitch_mean: Double
    let pitch_std: Double
    let pitch_min: Double
    let pitch_max: Double

    // Energy features
    let energy_mean: Double
    let energy_std: Double
    let energy_max: Double

    // Zero crossing rate (voice quality indicator)
    let zeroCrossingRate_mean: Double
    let zeroCrossingRate_std: Double

    // Speech rate
    let speechRate: Double

    func toDictionary() -> [String: Double] {
        return [
            "audio_mfcc0_mean": mfcc0_mean,
            "audio_mfcc0_std": mfcc0_std,
            "audio_mfcc1_mean": mfcc1_mean,
            "audio_mfcc1_std": mfcc1_std,
            "audio_mfcc2_mean": mfcc2_mean,
            "audio_mfcc2_std": mfcc2_std,
            "audio_mfcc3_mean": mfcc3_mean,
            "audio_mfcc3_std": mfcc3_std,
            "audio_mfcc4_mean": mfcc4_mean,
            "audio_mfcc4_std": mfcc4_std,
            "audio_mfcc5_mean": mfcc5_mean,
            "audio_mfcc5_std": mfcc5_std,
            "audio_pitch_mean": pitch_mean,
            "audio_pitch_std": pitch_std,
            "audio_pitch_min": pitch_min,
            "audio_pitch_max": pitch_max,
            "audio_energy_mean": energy_mean,
            "audio_energy_std": energy_std,
            "audio_energy_max": energy_max,
            "audio_zcr_mean": zeroCrossingRate_mean,
            "audio_zcr_std": zeroCrossingRate_std,
            "audio_speechRate": speechRate
        ]
    }
}

// MARK: - Feature Statistics Helper

/// Helper for calculating statistics from time series data
struct FeatureStatistics {
    static func calculateStats(from values: [Double]) -> (mean: Double, std: Double, min: Double, max: Double) {
        guard !values.isEmpty else {
            return (0.0, 0.0, 0.0, 0.0)
        }

        let mean = values.reduce(0.0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(values.count)
        let std = sqrt(variance)
        let min = values.min() ?? 0.0
        let max = values.max() ?? 0.0

        return (mean, std, min, max)
    }

    static func calculateMeanStd(from values: [Double]) -> (mean: Double, std: Double) {
        let stats = calculateStats(from: values)
        return (stats.mean, stats.std)
    }
}
