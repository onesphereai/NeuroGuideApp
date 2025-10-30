//
//  CameraPreviewView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 5 - Live Coach System (Camera Preview)
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
/// Displays live camera feed in the Live Coach interface
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        // Session is already set, no updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        private var orientationObserver: NSObjectProtocol?

        init() {
            // Observe device orientation changes
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateOrientation()
            }
        }

        deinit {
            // Clean up observer
            if let observer = orientationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        private func updateOrientation() {
            // Orientation updates handled by PreviewContainerView
        }
    }
}

/// Custom UIView that uses AVCaptureVideoPreviewLayer as its backing layer
/// This ensures proper frame sizing and automatic layout updates
class PreviewContainerView: UIView {
    var session: AVCaptureSession? {
        didSet {
            if let session = session {
                previewLayer.session = session
            }
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }

    private func setupPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Frame is automatically managed by the layer
        // Update orientation if needed
        updateVideoOrientation()
    }

    private func updateVideoOrientation() {
        guard let connection = previewLayer.connection,
              connection.isVideoOrientationSupported else { return }

        // Get the interface orientation
        if let windowScene = window?.windowScene {
            let interfaceOrientation = windowScene.interfaceOrientation
            let videoOrientation: AVCaptureVideoOrientation?

            switch interfaceOrientation {
            case .portrait:
                videoOrientation = .portrait
            case .portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                videoOrientation = .landscapeLeft
            case .landscapeRight:
                videoOrientation = .landscapeRight
            default:
                videoOrientation = .portrait
            }

            if let orientation = videoOrientation {
                connection.videoOrientation = orientation
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // Mock preview for design purposes
    Rectangle()
        .fill(Color.black)
        .overlay(
            VStack {
                Image(systemName: "video.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
                Text("Camera Preview")
                    .foregroundColor(.white.opacity(0.5))
            }
        )
        .frame(height: 300)
}
