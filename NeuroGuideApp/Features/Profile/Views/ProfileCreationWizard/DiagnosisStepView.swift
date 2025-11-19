//
//  DiagnosisStepView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-11-01.
//  Unit 3 - Child Profile & Personalization (Diagnosis Support)
//

import SwiftUI
import UniformTypeIdentifiers

/// Diagnosis selection step of profile creation - Simplified multi-select version
struct DiagnosisStepView: View {
    @ObservedObject var viewModel: ProfileCreationViewModel
    @State private var showingDocumentPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Info card at the top
                InfoCard(
                    icon: "heart.text.square.fill",
                    title: "Personalized Support",
                    message: "Sharing a diagnosis helps us personalize recommendations. This is completely optional and kept private on your device."
                )
                .padding(.top)

                // Multi-select diagnosis section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Diagnoses (Select all that apply)")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    VStack(spacing: 12) {
                        ForEach(NeurodivergentDiagnosis.allCases.filter { $0 != .multiple }) { diagnosis in
                            MultiSelectDiagnosisCard(
                                diagnosis: diagnosis,
                                isSelected: viewModel.selectedDiagnoses.contains(diagnosis),
                                action: {
                                    withAnimation {
                                        if viewModel.selectedDiagnoses.contains(diagnosis) {
                                            viewModel.selectedDiagnoses.remove(diagnosis)
                                        } else {
                                            viewModel.selectedDiagnoses.insert(diagnosis)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }

                // Professionally diagnosed toggle
                if !viewModel.selectedDiagnoses.isEmpty && !viewModel.selectedDiagnoses.contains(.preferNotToSpecify) {
                    Toggle(isOn: $viewModel.professionallyDiagnosed) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Professionally diagnosed")
                                .font(.subheadline)
                            Text("By a licensed healthcare professional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

                    // Report upload section (only if professionally diagnosed)
                    if viewModel.professionallyDiagnosed {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Diagnosis Report")
                                    .font(.headline)
                                Text("(Optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let reportData = viewModel.diagnosisReportData {
                                // Report uploaded
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Report attached")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text("\(reportData.count / 1024) KB")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        viewModel.diagnosisReportData = nil
                                        viewModel.reportAnalysis = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.1))
                                )

                                // Show analysis if available
                                if viewModel.isAnalyzingReport {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Analyzing report...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                } else if let analysis = viewModel.reportAnalysis {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "lightbulb.fill")
                                                .foregroundColor(.orange)
                                            Text("Report Analysis")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }

                                        Text(analysis)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                }
                            } else {
                                // Upload button
                                Button(action: {
                                    showingDocumentPicker = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.title2)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Upload diagnosis report")
                                                .font(.subheadline)
                                                .fontWeight(.medium)

                                            Text("PDF or image (max 10MB)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Notes field
                if !viewModel.selectedDiagnoses.isEmpty && !viewModel.selectedDiagnoses.contains(.preferNotToSpecify) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Additional Notes")
                                .font(.headline)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("Any additional context to help personalize support")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $viewModel.diagnosisNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .accessibilityLabel("Additional notes about diagnosis")
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { result in
                switch result {
                case .success(let data):
                    viewModel.diagnosisReportData = data
                    // Analyze the report
                    Task {
                        await viewModel.analyzeReport(reportData: data)
                    }
                case .failure(let error):
                    print("Error picking document: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Multi-Select Diagnosis Card

struct MultiSelectDiagnosisCard: View {
    let diagnosis: NeurodivergentDiagnosis
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator (checkbox)
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray)

                // Icon
                Text(diagnosis.icon)
                    .font(.title2)
                    .accessibilityHidden(true)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(diagnosis.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(diagnosis.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(diagnosis.displayName). \(isSelected ? "Selected" : "Not selected")")
        .accessibilityHint("Double tap to toggle selection")
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let completion: (Result<Data, Error>) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (Result<Data, Error>) -> Void

        init(completion: @escaping (Result<Data, Error>) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            do {
                let data = try Data(contentsOf: url)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled
        }
    }
}

// MARK: - Preview

struct DiagnosisStepView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosisStepView(viewModel: ProfileCreationViewModel())
    }
}
