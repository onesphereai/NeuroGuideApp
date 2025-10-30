//
//  PerformanceDashboardView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 2.1 - Core ML Infrastructure
//

import SwiftUI
import Combine

/// Performance monitoring dashboard (Debug builds only)
struct PerformanceDashboardView: View {

    // MARK: - State

    @StateObject private var viewModel = PerformanceDashboardViewModel()
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Device Info Section
                    deviceInfoSection

                    // Battery Impact Section
                    batterySection

                    // Models Section
                    modelsSection

                    // Alerts Section
                    if !viewModel.activeAlerts.isEmpty {
                        alertsSection
                    }

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("ML Performance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }

    // MARK: - Device Info Section

    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                InfoRow(label: "Device", value: viewModel.deviceInfo.modelName)
                InfoRow(label: "iOS Version", value: viewModel.deviceInfo.iosVersionString)
                InfoRow(label: "Processor", value: viewModel.deviceInfo.processorType)
                InfoRow(label: "Performance Tier", value: viewModel.deviceInfo.performanceTier.displayName)
                InfoRow(label: "Neural Engine", value: viewModel.deviceInfo.hasNeuralEngine ? "Available" : "Not Available")
                InfoRow(label: "Total Memory", value: String(format: "%.1f GB", viewModel.deviceInfo.totalMemoryMB / 1024))
                InfoRow(label: "Available Memory", value: String(format: "%.1f MB", viewModel.deviceInfo.availableMemoryMB))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Battery Section

    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Impact")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                HStack {
                    Text("Current Impact")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f%%", viewModel.batteryImpact))
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.batteryImpact > 10 ? .red : .green)
                }

                HStack {
                    Text("Target")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("< 10% per 30min")
                        .foregroundColor(.secondary)
                }

                // Battery impact gauge
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(viewModel.batteryImpact > 10 ? Color.red : Color.green)
                            .frame(width: min(geometry.size.width * CGFloat(viewModel.batteryImpact / 20), geometry.size.width), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Models Section

    private var modelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ML Models")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(MLModelType.allCases, id: \.self) { modelType in
                ModelCard(modelType: modelType, viewModel: viewModel)
            }
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Alerts")
                .font(.headline)
                .foregroundColor(.red)

            ForEach(Array(viewModel.activeAlerts.enumerated()), id: \.element) { index, alert in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(alert.severity == .critical ? .red : .orange)

                    Text(alert.message)
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct ModelCard: View {
    let modelType: MLModelType
    @ObservedObject var viewModel: PerformanceDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(modelType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if modelType.isAvailable {
                    Circle()
                        .fill(viewModel.isModelLoaded(modelType) ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isModelLoaded(modelType) ? "Loaded" : "Not Loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            if let stats = viewModel.getStatistics(for: modelType) {
                VStack(spacing: 4) {
                    HStack {
                        Text("Avg Latency:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fms", stats.averageLatencyMs))
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Target: \(String(format: "%.0fms", modelType.latencyTarget * 1000))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("P95 Latency:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fms", stats.p95LatencyMs))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(stats.p95Latency > modelType.latencyTarget ? .red : .green)
                        Spacer()
                        Text("Compliance: \(String(format: "%.0f%%", stats.targetComplianceRate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Memory:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fMB", stats.averageMemoryMB))
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Inferences: \(stats.sampleCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - View Model

class PerformanceDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var deviceInfo: DeviceInfo
    @Published var batteryImpact: Double = 0.0
    @Published var activeAlerts: [PerformanceAlert] = []

    // MARK: - Private Properties

    private let deviceCapability: DeviceCapabilityService
    private let modelService: MLModelService
    private let performanceMonitor: ModelPerformanceMonitorProtocol
    private var timer: Timer?

    // MARK: - Initialization

    init(
        deviceCapability: DeviceCapabilityService = DeviceCapabilityManager.shared,
        modelService: MLModelService = MLModelManager.shared,
        performanceMonitor: ModelPerformanceMonitorProtocol = PerformanceMonitor.shared
    ) {
        self.deviceCapability = deviceCapability
        self.modelService = modelService
        self.performanceMonitor = performanceMonitor
        self.deviceInfo = deviceCapability.getDeviceInfo()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        // Update metrics every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func isModelLoaded(_ type: MLModelType) -> Bool {
        return modelService.isModelLoaded(type: type)
    }

    func getStatistics(for modelType: MLModelType) -> PerformanceStatistics? {
        return performanceMonitor.getStatistics(for: modelType)
    }

    // MARK: - Private Methods

    private func updateMetrics() {
        batteryImpact = performanceMonitor.getCurrentBatteryImpact()
        activeAlerts = performanceMonitor.getActiveAlerts()
        deviceInfo = deviceCapability.getDeviceInfo() // Refresh available memory
    }
}

// MARK: - Preview

#Preview {
    PerformanceDashboardView()
}
