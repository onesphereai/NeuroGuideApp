//
//  SearchHistoryView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// View displaying search history with ability to re-run searches
struct SearchHistoryView: View {
    @StateObject private var historyManager = SearchHistoryManager.shared
    @State private var searchText = ""
    @State private var showClearConfirmation = false
    let onSearchTap: (String) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                if filteredHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("Search History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search history")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !historyManager.history.isEmpty {
                        Button(action: { showClearConfirmation = true }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all search history? This cannot be undone.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            VStack(spacing: 12) {
                Text("No Search History")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(searchText.isEmpty
                     ? "Your recent searches will appear here"
                     : "No searches match '\(searchText)'")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(groupedHistory.keys.sorted(), id: \.self) { section in
                Section(header: Text(section)) {
                    ForEach(groupedHistory[section] ?? []) { item in
                        SearchHistoryRow(
                            item: item,
                            onTap: { onSearchTap(item.query) },
                            onDelete: { historyManager.removeSearch(id: item.id) }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Computed Properties

    private var filteredHistory: [SearchHistoryItem] {
        if searchText.isEmpty {
            return historyManager.history
        } else {
            return historyManager.searchHistory(matching: searchText)
        }
    }

    private var groupedHistory: [String: [SearchHistoryItem]] {
        Dictionary(grouping: filteredHistory) { $0.dateSection }
    }
}

// MARK: - Search History Row

struct SearchHistoryRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.query)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(item.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if item.answerCount > 0 {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(item.answerCount) answer\(item.answerCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Remove from History", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive, action: onDelete)
        } message: {
            Text("Remove '\(item.query)' from your search history?")
        }
    }
}

// MARK: - Recent Searches Component

/// Compact component showing recent searches (for use in main Ask view)
struct RecentSearchesView: View {
    @StateObject private var historyManager = SearchHistoryManager.shared
    let onSearchTap: (String) -> Void
    let limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                Text("Recent Searches")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(historyManager.getRecentSearches(limit: limit)) { item in
                    Button(action: { onSearchTap(item.query) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(item.query)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    SearchHistoryView(onSearchTap: { _ in })
}
