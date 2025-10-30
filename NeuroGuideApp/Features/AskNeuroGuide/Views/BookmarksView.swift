//
//  BookmarksView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// View displaying all bookmarked content
struct BookmarksView: View {
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var sortOption: SortOption = .date
    @State private var showDeleteConfirmation = false
    @State private var bookmarkToDelete: Bookmark?

    enum SortOption: String, CaseIterable {
        case date = "Date"
        case credibility = "Credibility"

        var icon: String {
            switch self {
            case .date: return "calendar"
            case .credibility: return "star.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                if bookmarkManager.bookmarks.isEmpty {
                    emptyState
                } else {
                    bookmarksList
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !bookmarkManager.bookmarks.isEmpty {
                        BookmarksShareButton(bookmarks: sortedBookmarks)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
            .alert("Remove Bookmark", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let bookmark = bookmarkToDelete {
                        bookmarkManager.removeBookmark(id: bookmark.id)
                    }
                }
            } message: {
                if let bookmark = bookmarkToDelete {
                    Text("Are you sure you want to remove '\(bookmark.displayName)' from your bookmarks?")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            VStack(spacing: 12) {
                Text("No Bookmarks Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Bookmark helpful answers while asking attune to save them for later")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Bookmarks List

    private var bookmarksList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedBookmarks) { bookmark in
                    BookmarkCard(
                        bookmark: bookmark,
                        onDelete: {
                            bookmarkToDelete = bookmark
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: { sortOption = option }) {
                    HStack {
                        Text(option.rawValue)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    // MARK: - Computed Properties

    private var sortedBookmarks: [Bookmark] {
        switch sortOption {
        case .date:
            return bookmarkManager.getBookmarksByDate()
        case .credibility:
            return bookmarkManager.getBookmarksByCredibility()
        }
    }
}

// MARK: - Bookmark Card

struct BookmarkCard: View {
    let bookmark: Bookmark
    let onDelete: () -> Void
    @State private var isExpanded = false
    @State private var showSourceDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question asked
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(bookmark.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Share button
                ShareButton(answer: bookmark.answer, question: bookmark.question, format: .both)

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Source header
            HStack(spacing: 8) {
                CredibilityBadge(level: bookmark.answer.source.credibilityLevel, compact: true)

                Text(bookmark.answer.source.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                // Info button
                Button(action: { showSourceDetails = true }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            // Author
            if let author = bookmark.answer.source.author {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(author)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                // Content
                Text(bookmark.answer.content)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                // Strategies (if any)
                if let strategies = bookmark.answer.strategies, !strategies.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Strategies")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(strategies, id: \.id) { strategy in
                            HStack(spacing: 8) {
                                Image(systemName: strategy.category.icon)
                                    .font(.caption)
                                    .foregroundColor(strategy.category.color)

                                Text(strategy.description)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }

            // Expand/collapse button
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showSourceDetails) {
            SourceDetailsSheet(source: bookmark.answer.source)
        }
    }
}

// MARK: - Preview

#Preview {
    BookmarksView()
}
