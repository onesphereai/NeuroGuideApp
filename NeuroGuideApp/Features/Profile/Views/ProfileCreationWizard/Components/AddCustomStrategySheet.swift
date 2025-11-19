//
//  AddCustomStrategySheet.swift
//  NeuroGuide
//
//  Created for AT-19: Co-Regulation Q2 Rating
//  Sheet for adding custom calming strategies
//

import SwiftUI

struct AddCustomStrategySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var strategyName: String = ""
    @State private var strategyExample: String = ""
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    let onAdd: (CalmingStrategyRating) -> Void
    
    private let maxNameLength = 100
    private let maxExampleLength = 200
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                TextField("Strategy name (required)", text: $strategyName)
                        .onChange(of: strategyName) { newValue in
                            if newValue.count > maxNameLength {
                                strategyName = String(newValue.prefix(maxNameLength))
                            }
                        }
                    
                    Text("\(strategyName.count)/\(maxNameLength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: {
                    Text("Strategy Name")
                } footer: {
                    Text("Give your calming strategy a clear, descriptive name.")
                }
                
                Section {
                    TextField("Example or description (optional)", text: $strategyExample, axis: .vertical)
                        .lineLimit(3...5)
                        .onChange(of: strategyExample) { newValue in
                            if newValue.count > maxExampleLength {
                                strategyExample = String(newValue.prefix(maxExampleLength))
                            }
                        }
                    
                    Text("\(strategyExample.count)/\(maxExampleLength)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: {
                    Text("Example")
                } footer: {
                    Text("Provide a brief example or description of how this strategy works.")
                }
            }
            .navigationTitle("Add Custom Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStrategy()
                    }
                    .disabled(strategyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addStrategy() {
        let trimmedName = strategyName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a strategy name."
            showingError = true
            return
        }
        
        let newStrategy = CalmingStrategyRating.createCustomStrategy(
            name: trimmedName,
            example: strategyExample.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : strategyExample.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        onAdd(newStrategy)
        dismiss()
    }
}

#Preview {
    AddCustomStrategySheet { strategy in
        print("Added strategy: \(strategy.strategyName)")
    }
}
