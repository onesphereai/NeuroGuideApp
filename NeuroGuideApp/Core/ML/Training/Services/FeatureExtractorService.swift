//
//  FeatureExtractorService.swift
//  NeuroGuide
//
//  Extracts multimodal features from training videos for ML model training
//

import Foundation
import AVFoundation
import Vision
import CoreImage
import Accelerate

/// Service for extracting features from training videos
@MainActor
class FeatureExtractorService {

    // MARK: - Singleton

    static let shared = FeatureExtractorService()

    // MARK: - Private Properties

    private let poseExtractor = PoseFeatureExtractor()
    private let facialExtractor = FacialFeatureExtractor()
    private let audioExtractor = AudioFeatureExtractor()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Extract all features from a training video
    func extractFeatures(from video: TrainingVideo) async throws -> ExtractedFeatures {
        print("🔬 Starting feature extraction for video: \(video.id)")

        // Validate video file exists
        guard FileManager.default.fileExists(atPath: video.videoURL.path) else {
            print("❌ Video file does not exist: \(video.videoURL.path)")
            throw FeatureExtractionError.videoFileNotFound(video.id, video.videoURL)
        }

        // Load video asset
        let asset = AVURLAsset(url: video.videoURL)

        // Extract features in parallel
        async let poseFeatures = extractPoseFeatures(from: asset)
        async let facialFeatures = extractFacialFeatures(from: asset)

        // Wait for video extractions to complete
        let (pose, facial) = try await (poseFeatures, facialFeatures)

        // Try to extract audio (optional - videos might not have audio track)
        let audio: AudioFeatureVector?
        do {
            audio = try await extractAudioFeatures(from: asset)
            print("✅ Audio features extracted")
        } catch FeatureExtractionError.noAudioTrack {
            print("ℹ️ No audio track in video, using default audio features")
            audio = nil
        } catch {
            print("⚠️ Audio extraction failed: \(error.localizedDescription), using default")
            audio = nil
        }

        print("✅ Feature extraction complete for video: \(video.id)")

        return ExtractedFeatures(
            videoID: video.id,
            childID: video.childID,
            arousalState: video.arousalState,
            extractedAt: Date(),
            poseFeatures: pose,
            facialFeatures: facial,
            audioFeatures: audio ?? createDefaultAudioFeatures()
        )
    }

    /// Extract features from multiple videos
    func extractFeatures(from videos: [TrainingVideo], progressCallback: ((Double) -> Void)? = nil) async throws -> [ExtractedFeatures] {
        var extractedFeatures: [ExtractedFeatures] = []

        for (index, video) in videos.enumerated() {
            do {
                let features = try await extractFeatures(from: video)
                extractedFeatures.append(features)

                // Report progress
                let progress = Double(index + 1) / Double(videos.count)
                progressCallback?(progress)
            } catch {
                print("⚠️ Failed to extract features from video \(video.id): \(error)")
                throw FeatureExtractionError.videoProcessingFailed(video.id, error)
            }
        }

        return extractedFeatures
    }

    // MARK: - Private Methods

    private func extractPoseFeatures(from asset: AVAsset) async throws -> PoseFeatureVector {
        return try await poseExtractor.extract(from: asset)
    }

    private func extractFacialFeatures(from asset: AVAsset) async throws -> FacialFeatureVector {
        return try await facialExtractor.extract(from: asset)
    }

    private func extractAudioFeatures(from asset: AVAsset) async throws -> AudioFeatureVector {
        return try await audioExtractor.extract(from: asset)
    }

    /// Create default audio features for videos without audio
    private func createDefaultAudioFeatures() -> AudioFeatureVector {
        // Return neutral/silent audio features
        return AudioFeatureVector(
            mfcc0_mean: 0.0, mfcc0_std: 0.0,
            mfcc1_mean: 0.0, mfcc1_std: 0.0,
            mfcc2_mean: 0.0, mfcc2_std: 0.0,
            mfcc3_mean: 0.0, mfcc3_std: 0.0,
            mfcc4_mean: 0.0, mfcc4_std: 0.0,
            mfcc5_mean: 0.0, mfcc5_std: 0.0,
            pitch_mean: 0.0, pitch_std: 0.0, pitch_min: 0.0, pitch_max: 0.0,
            energy_mean: 0.0, energy_std: 0.0, energy_max: 0.0,
            zeroCrossingRate_mean: 0.0, zeroCrossingRate_std: 0.0,
            speechRate: 0.0
        )
    }
}

// MARK: - Pose Feature Extractor

class PoseFeatureExtractor {

    func extract(from asset: AVAsset) async throws -> PoseFeatureVector {
        // Extract frames from video
        let frames = try await extractFrames(from: asset, maxFrames: 30) // ~3fps for 10 seconds

        // Track pose data over time
        var headXValues: [Double] = []
        var headYValues: [Double] = []
        var torsoXValues: [Double] = []
        var torsoYValues: [Double] = []
        var leftArmXValues: [Double] = []
        var leftArmYValues: [Double] = []
        var rightArmXValues: [Double] = []
        var rightArmYValues: [Double] = []
        var leftLegXValues: [Double] = []
        var leftLegYValues: [Double] = []
        var rightLegXValues: [Double] = []
        var rightLegYValues: [Double] = []
        var velocities: [Double] = []
        var opennessValues: [Double] = []
        var angleValues: [Double] = []

        // Process each frame
        for frame in frames {
            if let poseData = try? await detectPose(in: frame) {
                headXValues.append(poseData.headX)
                headYValues.append(poseData.headY)
                torsoXValues.append(poseData.torsoX)
                torsoYValues.append(poseData.torsoY)
                leftArmXValues.append(poseData.leftArmX)
                leftArmYValues.append(poseData.leftArmY)
                rightArmXValues.append(poseData.rightArmX)
                rightArmYValues.append(poseData.rightArmY)
                leftLegXValues.append(poseData.leftLegX)
                leftLegYValues.append(poseData.leftLegY)
                rightLegXValues.append(poseData.rightLegX)
                rightLegYValues.append(poseData.rightLegY)
                velocities.append(poseData.velocity)
                opennessValues.append(poseData.openness)
                angleValues.append(poseData.angle)
            }
        }

        // Calculate statistics
        let headXStats = FeatureStatistics.calculateMeanStd(from: headXValues)
        let headYStats = FeatureStatistics.calculateMeanStd(from: headYValues)
        let torsoXStats = FeatureStatistics.calculateMeanStd(from: torsoXValues)
        let torsoYStats = FeatureStatistics.calculateMeanStd(from: torsoYValues)
        let leftArmXStats = FeatureStatistics.calculateMeanStd(from: leftArmXValues)
        let leftArmYStats = FeatureStatistics.calculateMeanStd(from: leftArmYValues)
        let rightArmXStats = FeatureStatistics.calculateMeanStd(from: rightArmXValues)
        let rightArmYStats = FeatureStatistics.calculateMeanStd(from: rightArmYValues)
        let leftLegXStats = FeatureStatistics.calculateMeanStd(from: leftLegXValues)
        let leftLegYStats = FeatureStatistics.calculateMeanStd(from: leftLegYValues)
        let rightLegXStats = FeatureStatistics.calculateMeanStd(from: rightLegXValues)
        let rightLegYStats = FeatureStatistics.calculateMeanStd(from: rightLegYValues)
        let velocityStats = FeatureStatistics.calculateStats(from: velocities)
        let opennessStats = FeatureStatistics.calculateMeanStd(from: opennessValues)
        let angleStats = FeatureStatistics.calculateMeanStd(from: angleValues)

        return PoseFeatureVector(
            headX_mean: headXStats.mean,
            headX_std: headXStats.std,
            headY_mean: headYStats.mean,
            headY_std: headYStats.std,
            torsoX_mean: torsoXStats.mean,
            torsoX_std: torsoXStats.std,
            torsoY_mean: torsoYStats.mean,
            torsoY_std: torsoYStats.std,
            leftArmX_mean: leftArmXStats.mean,
            leftArmX_std: leftArmXStats.std,
            leftArmY_mean: leftArmYStats.mean,
            leftArmY_std: leftArmYStats.std,
            rightArmX_mean: rightArmXStats.mean,
            rightArmX_std: rightArmXStats.std,
            rightArmY_mean: rightArmYStats.mean,
            rightArmY_std: rightArmYStats.std,
            leftLegX_mean: leftLegXStats.mean,
            leftLegX_std: leftLegXStats.std,
            leftLegY_mean: leftLegYStats.mean,
            leftLegY_std: leftLegYStats.std,
            rightLegX_mean: rightLegXStats.mean,
            rightLegX_std: rightLegXStats.std,
            rightLegY_mean: rightLegYStats.mean,
            rightLegY_std: rightLegYStats.std,
            overallVelocity_mean: velocityStats.mean,
            overallVelocity_std: velocityStats.std,
            overallVelocity_max: velocityStats.max,
            bodyOpenness_mean: opennessStats.mean,
            bodyOpenness_std: opennessStats.std,
            postureAngle_mean: angleStats.mean,
            postureAngle_std: angleStats.std
        )
    }

    private func detectPose(in image: CGImage) async throws -> TrainingPoseData {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNHumanBodyPoseObservation],
                      let observation = observations.first else {
                    continuation.resume(throwing: FeatureExtractionError.poseDetectionFailed)
                    return
                }

                do {
                    let poseData = try self.extractPoseData(from: observation)
                    continuation.resume(returning: poseData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func extractPoseData(from observation: VNHumanBodyPoseObservation) throws -> TrainingPoseData {
        // Get key points
        let nose = try observation.recognizedPoint(.nose)
        let neck = try observation.recognizedPoint(.neck)
        let leftShoulder = try observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try observation.recognizedPoint(.rightShoulder)
        let leftElbow = try observation.recognizedPoint(.leftElbow)
        let rightElbow = try observation.recognizedPoint(.rightElbow)
        let leftWrist = try observation.recognizedPoint(.leftWrist)
        let rightWrist = try observation.recognizedPoint(.rightWrist)
        let leftHip = try observation.recognizedPoint(.leftHip)
        let rightHip = try observation.recognizedPoint(.rightHip)
        let leftKnee = try observation.recognizedPoint(.leftKnee)
        let rightKnee = try observation.recognizedPoint(.rightKnee)

        // Calculate features
        let headX = Double(nose.location.x)
        let headY = Double(nose.location.y)
        let torsoX = Double((leftShoulder.location.x + rightShoulder.location.x) / 2)
        let torsoY = Double((leftShoulder.location.y + rightShoulder.location.y) / 2)

        let leftArmX = Double((leftShoulder.location.x + leftWrist.location.x) / 2)
        let leftArmY = Double((leftShoulder.location.y + leftWrist.location.y) / 2)
        let rightArmX = Double((rightShoulder.location.x + rightWrist.location.x) / 2)
        let rightArmY = Double((rightShoulder.location.y + rightWrist.location.y) / 2)

        let leftLegX = Double((leftHip.location.x + leftKnee.location.x) / 2)
        let leftLegY = Double((leftHip.location.y + leftKnee.location.y) / 2)
        let rightLegX = Double((rightHip.location.x + rightKnee.location.x) / 2)
        let rightLegY = Double((rightHip.location.y + rightKnee.location.y) / 2)

        // Calculate velocity (simplified - distance moved)
        let velocity = sqrt(pow(headX - torsoX, 2) + pow(headY - torsoY, 2))

        // Calculate body openness (width between arms)
        let openness = abs(leftWrist.location.x - rightWrist.location.x)

        // Calculate posture angle (torso tilt)
        let angle = atan2(Double(neck.location.y - torsoY), Double(neck.location.x - torsoX))

        return TrainingPoseData(
            headX: headX, headY: headY,
            torsoX: torsoX, torsoY: torsoY,
            leftArmX: leftArmX, leftArmY: leftArmY,
            rightArmX: rightArmX, rightArmY: rightArmY,
            leftLegX: leftLegX, leftLegY: leftLegY,
            rightLegX: rightLegX, rightLegY: rightLegY,
            velocity: velocity,
            openness: Double(openness),
            angle: angle
        )
    }

    private func extractFrames(from asset: AVAsset, maxFrames: Int) async throws -> [CGImage] {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw FeatureExtractionError.noVideoTrack
        }

        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        let interval = durationSeconds / Double(maxFrames)

        var frames: [CGImage] = []
        for i in 0..<maxFrames {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                frames.append(cgImage)
            } catch {
                print("⚠️ Failed to extract frame at time \(time.seconds): \(error)")
            }
        }

        return frames
    }
}

// MARK: - Training Pose Data Helper

struct TrainingPoseData {
    let headX: Double
    let headY: Double
    let torsoX: Double
    let torsoY: Double
    let leftArmX: Double
    let leftArmY: Double
    let rightArmX: Double
    let rightArmY: Double
    let leftLegX: Double
    let leftLegY: Double
    let rightLegX: Double
    let rightLegY: Double
    let velocity: Double
    let openness: Double
    let angle: Double
}

// MARK: - Facial Feature Extractor

class FacialFeatureExtractor {

    func extract(from asset: AVAsset) async throws -> FacialFeatureVector {
        // Extract frames from video
        let frames = try await extractFrames(from: asset, maxFrames: 30)

        // Track facial data over time
        var leftEyeOpenValues: [Double] = []
        var rightEyeOpenValues: [Double] = []
        var mouthOpenValues: [Double] = []
        var mouthWidthValues: [Double] = []
        var leftBrowValues: [Double] = []
        var rightBrowValues: [Double] = []
        var browRaiseValues: [Double] = []
        var browLowerValues: [Double] = []
        var smileValues: [Double] = []
        var jawValues: [Double] = []
        var cheekValues: [Double] = []
        var yawValues: [Double] = []
        var pitchValues: [Double] = []
        var rollValues: [Double] = []

        // Process each frame
        for frame in frames {
            if let faceData = try? await detectFace(in: frame) {
                leftEyeOpenValues.append(faceData.leftEyeOpen)
                rightEyeOpenValues.append(faceData.rightEyeOpen)
                mouthOpenValues.append(faceData.mouthOpen)
                mouthWidthValues.append(faceData.mouthWidth)
                leftBrowValues.append(faceData.leftBrow)
                rightBrowValues.append(faceData.rightBrow)
                browRaiseValues.append(faceData.browRaise)
                browLowerValues.append(faceData.browLower)
                smileValues.append(faceData.smile)
                jawValues.append(faceData.jaw)
                cheekValues.append(faceData.cheek)
                yawValues.append(faceData.yaw)
                pitchValues.append(faceData.pitch)
                rollValues.append(faceData.roll)
            }
        }

        // Calculate statistics
        let leftEyeStats = FeatureStatistics.calculateMeanStd(from: leftEyeOpenValues)
        let rightEyeStats = FeatureStatistics.calculateMeanStd(from: rightEyeOpenValues)
        let mouthOpenStats = FeatureStatistics.calculateMeanStd(from: mouthOpenValues)
        let mouthWidthStats = FeatureStatistics.calculateMeanStd(from: mouthWidthValues)
        let leftBrowStats = FeatureStatistics.calculateMeanStd(from: leftBrowValues)
        let rightBrowStats = FeatureStatistics.calculateMeanStd(from: rightBrowValues)
        let browRaiseStats = FeatureStatistics.calculateMeanStd(from: browRaiseValues)
        let browLowerStats = FeatureStatistics.calculateMeanStd(from: browLowerValues)
        let smileStats = FeatureStatistics.calculateMeanStd(from: smileValues)
        let jawStats = FeatureStatistics.calculateMeanStd(from: jawValues)
        let cheekStats = FeatureStatistics.calculateMeanStd(from: cheekValues)
        let yawStats = FeatureStatistics.calculateMeanStd(from: yawValues)
        let pitchStats = FeatureStatistics.calculateMeanStd(from: pitchValues)
        let rollStats = FeatureStatistics.calculateMeanStd(from: rollValues)

        return FacialFeatureVector(
            leftEyeOpenness_mean: leftEyeStats.mean,
            leftEyeOpenness_std: leftEyeStats.std,
            rightEyeOpenness_mean: rightEyeStats.mean,
            rightEyeOpenness_std: rightEyeStats.std,
            mouthOpenness_mean: mouthOpenStats.mean,
            mouthOpenness_std: mouthOpenStats.std,
            mouthWidth_mean: mouthWidthStats.mean,
            mouthWidth_std: mouthWidthStats.std,
            leftBrowHeight_mean: leftBrowStats.mean,
            leftBrowHeight_std: leftBrowStats.std,
            rightBrowHeight_mean: rightBrowStats.mean,
            rightBrowHeight_std: rightBrowStats.std,
            browRaiser_mean: browRaiseStats.mean,
            browRaiser_std: browRaiseStats.std,
            browLowerer_mean: browLowerStats.mean,
            browLowerer_std: browLowerStats.std,
            lipCornerPuller_mean: smileStats.mean,
            lipCornerPuller_std: smileStats.std,
            jawDrop_mean: jawStats.mean,
            jawDrop_std: jawStats.std,
            cheekRaiser_mean: cheekStats.mean,
            cheekRaiser_std: cheekStats.std,
            headYaw_mean: yawStats.mean,
            headYaw_std: yawStats.std,
            headPitch_mean: pitchStats.mean,
            headPitch_std: pitchStats.std,
            headRoll_mean: rollStats.mean,
            headRoll_std: rollStats.std
        )
    }

    private func detectFace(in image: CGImage) async throws -> FaceData {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNFaceObservation],
                      let observation = observations.first else {
                    continuation.resume(throwing: FeatureExtractionError.faceDetectionFailed)
                    return
                }

                do {
                    let faceData = try self.extractFaceData(from: observation)
                    continuation.resume(returning: faceData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func extractFaceData(from observation: VNFaceObservation) throws -> FaceData {
        guard let landmarks = observation.landmarks else {
            throw FeatureExtractionError.landmarksNotFound
        }

        // Extract eye openness (distance between upper and lower eyelid)
        let leftEyeOpen = landmarks.leftEye.map { calculateOpenness($0.normalizedPoints) } ?? 0.5
        let rightEyeOpen = landmarks.rightEye.map { calculateOpenness($0.normalizedPoints) } ?? 0.5

        // Extract mouth features
        let mouthOpen = landmarks.innerLips.map { calculateOpenness($0.normalizedPoints) } ?? 0.0
        let mouthWidth = landmarks.outerLips.map { calculateWidth($0.normalizedPoints) } ?? 0.5

        // Extract brow heights
        let leftBrow = landmarks.leftEyebrow.map { $0.normalizedPoints.map { $0.y }.max() ?? 0.5 } ?? 0.5
        let rightBrow = landmarks.rightEyebrow.map { $0.normalizedPoints.map { $0.y }.max() ?? 0.5 } ?? 0.5

        // Action units (simplified estimates based on landmarks)
        let browRaise = max(leftBrow, rightBrow) - 0.5  // baseline 0.5
        let browLower = 0.5 - min(leftBrow, rightBrow)
        let smile = mouthWidth * 0.8  // smile correlates with mouth width
        let jaw = mouthOpen
        let cheek = smile * 0.7  // cheek raise correlates with smile

        // Head pose (yaw, pitch, roll)
        let yaw = Double(observation.yaw?.doubleValue ?? 0.0)
        let pitch = Double(observation.pitch?.doubleValue ?? 0.0)
        let roll = Double(observation.roll?.doubleValue ?? 0.0)

        return FaceData(
            leftEyeOpen: leftEyeOpen,
            rightEyeOpen: rightEyeOpen,
            mouthOpen: mouthOpen,
            mouthWidth: mouthWidth,
            leftBrow: leftBrow,
            rightBrow: rightBrow,
            browRaise: browRaise,
            browLower: browLower,
            smile: smile,
            jaw: jaw,
            cheek: cheek,
            yaw: yaw,
            pitch: pitch,
            roll: roll
        )
    }

    private func calculateOpenness(_ points: [CGPoint]) -> Double {
        guard points.count >= 6 else { return 0.5 }
        let topY = points[0..<points.count/2].map { $0.y }.max() ?? 0.5
        let bottomY = points[points.count/2..<points.count].map { $0.y }.min() ?? 0.5
        return abs(Double(topY - bottomY))
    }

    private func calculateWidth(_ points: [CGPoint]) -> Double {
        guard !points.isEmpty else { return 0.5 }
        let leftX = points.map { $0.x }.min() ?? 0.0
        let rightX = points.map { $0.x }.max() ?? 1.0
        return abs(Double(rightX - leftX))
    }

    private func extractFrames(from asset: AVAsset, maxFrames: Int) async throws -> [CGImage] {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw FeatureExtractionError.noVideoTrack
        }

        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        let interval = durationSeconds / Double(maxFrames)

        var frames: [CGImage] = []
        for i in 0..<maxFrames {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                frames.append(cgImage)
            } catch {
                print("⚠️ Failed to extract frame at time \(time.seconds): \(error)")
            }
        }

        return frames
    }
}

// MARK: - Face Data Helper

struct FaceData {
    let leftEyeOpen: Double
    let rightEyeOpen: Double
    let mouthOpen: Double
    let mouthWidth: Double
    let leftBrow: Double
    let rightBrow: Double
    let browRaise: Double
    let browLower: Double
    let smile: Double
    let jaw: Double
    let cheek: Double
    let yaw: Double
    let pitch: Double
    let roll: Double
}

// MARK: - Audio Feature Extractor

class AudioFeatureExtractor {

    func extract(from asset: AVAsset) async throws -> AudioFeatureVector {
        // Extract audio samples
        let samples = try await extractAudioSamples(from: asset)

        guard !samples.isEmpty else {
            throw FeatureExtractionError.noAudioData
        }

        // Calculate MFCC features (simplified - using energy in frequency bands)
        let mfccFeatures = calculateMFCC(from: samples)

        // Calculate pitch features
        let pitchFeatures = calculatePitch(from: samples)

        // Calculate energy features
        let energyFeatures = calculateEnergy(from: samples)

        // Calculate zero crossing rate
        let zcrFeatures = calculateZeroCrossingRate(from: samples)

        // Estimate speech rate (simplified)
        let speechRate = estimateSpeechRate(from: samples)

        return AudioFeatureVector(
            mfcc0_mean: mfccFeatures[0].mean,
            mfcc0_std: mfccFeatures[0].std,
            mfcc1_mean: mfccFeatures[1].mean,
            mfcc1_std: mfccFeatures[1].std,
            mfcc2_mean: mfccFeatures[2].mean,
            mfcc2_std: mfccFeatures[2].std,
            mfcc3_mean: mfccFeatures[3].mean,
            mfcc3_std: mfccFeatures[3].std,
            mfcc4_mean: mfccFeatures[4].mean,
            mfcc4_std: mfccFeatures[4].std,
            mfcc5_mean: mfccFeatures[5].mean,
            mfcc5_std: mfccFeatures[5].std,
            pitch_mean: pitchFeatures.mean,
            pitch_std: pitchFeatures.std,
            pitch_min: pitchFeatures.min,
            pitch_max: pitchFeatures.max,
            energy_mean: energyFeatures.mean,
            energy_std: energyFeatures.std,
            energy_max: energyFeatures.max,
            zeroCrossingRate_mean: zcrFeatures.mean,
            zeroCrossingRate_std: zcrFeatures.std,
            speechRate: speechRate
        )
    }

    private func extractAudioSamples(from asset: AVAsset) async throws -> [Float] {
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw FeatureExtractionError.noAudioTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(output)
        reader.startReading()

        var samples: [Float] = []

        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }

            var length: Int = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

            guard let data = dataPointer else { continue }

            let int16Pointer = data.withMemoryRebound(to: Int16.self, capacity: length / 2) { $0 }
            for i in 0..<(length / 2) {
                let sample = Float(int16Pointer[i]) / Float(Int16.max)
                samples.append(sample)
            }
        }

        return samples
    }

    private func calculateMFCC(from samples: [Float]) -> [(mean: Double, std: Double)] {
        // Simplified MFCC calculation (using 6 frequency band energies)
        var mfccResults: [(mean: Double, std: Double)] = []

        for _ in 0..<6 {
            // In real implementation, would use FFT and mel-scale filterbanks
            // For now, using placeholder energy calculation
            let stats = FeatureStatistics.calculateMeanStd(from: samples.map { Double($0) })
            mfccResults.append(stats)
        }

        return mfccResults
    }

    private func calculatePitch(from samples: [Float]) -> (mean: Double, std: Double, min: Double, max: Double) {
        // Simplified pitch calculation using autocorrelation
        // In real implementation, would use autocorrelation or YIN algorithm
        let values = samples.map { Double(abs($0)) }
        return FeatureStatistics.calculateStats(from: values)
    }

    private func calculateEnergy(from samples: [Float]) -> (mean: Double, std: Double, max: Double) {
        let energyValues = samples.map { Double($0 * $0) }
        let stats = FeatureStatistics.calculateStats(from: energyValues)
        return (stats.mean, stats.std, stats.max)
    }

    private func calculateZeroCrossingRate(from samples: [Float]) -> (mean: Double, std: Double) {
        var zcrValues: [Double] = []
        let windowSize = 1024

        for i in stride(from: 0, to: samples.count - windowSize, by: windowSize) {
            var crossings = 0
            for j in i..<(i + windowSize - 1) {
                if (samples[j] >= 0 && samples[j + 1] < 0) || (samples[j] < 0 && samples[j + 1] >= 0) {
                    crossings += 1
                }
            }
            zcrValues.append(Double(crossings) / Double(windowSize))
        }

        return FeatureStatistics.calculateMeanStd(from: zcrValues)
    }

    private func estimateSpeechRate(from samples: [Float]) -> Double {
        // Simplified speech rate estimation
        // Count energy peaks as proxy for syllables
        let threshold: Float = 0.1
        var peaks = 0

        for i in 1..<(samples.count - 1) {
            if samples[i] > threshold && samples[i] > samples[i-1] && samples[i] > samples[i+1] {
                peaks += 1
            }
        }

        // Assuming ~44100 Hz sample rate and 10 seconds
        let durationSeconds = 10.0
        return Double(peaks) / durationSeconds
    }
}

// MARK: - Errors

enum FeatureExtractionError: LocalizedError {
    case videoFileNotFound(UUID, URL)
    case videoProcessingFailed(UUID, Error)
    case poseDetectionFailed
    case faceDetectionFailed
    case landmarksNotFound
    case noVideoTrack
    case noAudioTrack
    case noAudioData

    var errorDescription: String? {
        switch self {
        case .videoFileNotFound(let videoID, let url):
            return "Video file not found at \(url.path). The file may have been deleted or never saved properly."
        case .videoProcessingFailed(let videoID, let error):
            return "Failed to process video \(videoID): \(error.localizedDescription)"
        case .poseDetectionFailed:
            return "No pose detected in video frame"
        case .faceDetectionFailed:
            return "No face detected in video frame"
        case .landmarksNotFound:
            return "Facial landmarks not found"
        case .noVideoTrack:
            return "No video track found in asset"
        case .noAudioTrack:
            return "No audio track found in asset"
        case .noAudioData:
            return "No audio data extracted from video"
        }
    }
}
