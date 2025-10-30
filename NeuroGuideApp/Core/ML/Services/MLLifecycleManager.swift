//
//  MLLifecycleManager.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import Foundation
import UIKit
import Combine

/// Manages ML operations lifecycle based on app state
class MLLifecycleManager {

    // MARK: - Singleton

    static let shared = MLLifecycleManager()

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let modelService: MLModelService
    private let performanceMonitor: ModelPerformanceMonitorProtocol
    private let privacyService: PrivacyServiceProtocol
    private var isMLActive = false

    // MARK: - Initialization

    private init(
        modelService: MLModelService = MLModelManager.shared,
        performanceMonitor: ModelPerformanceMonitorProtocol = PerformanceMonitor.shared,
        privacyService: PrivacyServiceProtocol = PrivacyManager.shared
    ) {
        self.modelService = modelService
        self.performanceMonitor = performanceMonitor
        self.privacyService = privacyService

        setupAppLifecycleObservers()
    }

    // MARK: - Public Methods

    /// Start ML operations
    func startMLOperations() {
        guard !isMLActive else { return }

        isMLActive = true
        performanceMonitor.startMonitoring()
        privacyService.startNetworkMonitoring()

        print("🚀 ML operations started")
    }

    /// Stop ML operations
    func stopMLOperations() {
        guard isMLActive else { return }

        isMLActive = false
        performanceMonitor.stopMonitoring()
        privacyService.stopNetworkMonitoring()

        print("🛑 ML operations stopped")
    }

    /// Suspend ML operations (when app backgrounds)
    func suspendMLOperations() {
        guard isMLActive else { return }

        // Stop monitoring
        performanceMonitor.stopMonitoring()
        privacyService.stopNetworkMonitoring()

        // Unload non-essential models to save memory
        modelService.unloadAllModels()

        print("💤 ML operations suspended")
    }

    /// Resume ML operations (when app foregrounds)
    func resumeMLOperations() {
        guard isMLActive else { return }

        // Restart monitoring
        performanceMonitor.startMonitoring()
        privacyService.startNetworkMonitoring()

        print("▶️ ML operations resumed")
    }

    /// Check if ML operations are active
    func isActive() -> Bool {
        return isMLActive
    }

    // MARK: - Private Methods

    private func setupAppLifecycleObservers() {
        // Observe app entering background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)

        // Observe app entering foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)

        // Observe app terminating
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleAppWillTerminate()
            }
            .store(in: &cancellables)

        // Observe memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }

    private func handleAppDidEnterBackground() {
        print("📱 App entered background")
        suspendMLOperations()
    }

    private func handleAppWillEnterForeground() {
        print("📱 App will enter foreground")
        resumeMLOperations()
    }

    private func handleAppWillTerminate() {
        print("📱 App will terminate")
        stopMLOperations()
    }

    private func handleMemoryWarning() {
        print("⚠️ Memory warning received")

        // Unload all models to free memory
        modelService.unloadAllModels()

        // Force garbage collection
        print("🗑️ Freed ML model memory")
    }
}
