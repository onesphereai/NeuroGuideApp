//
//  ShareSheet.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for UIActivityViewController (native iOS share sheet)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Share Button Component

/// Reusable share button component
struct ShareButton: View {
    let answer: ContentAnswer
    let question: String?
    let format: ShareFormat
    @State private var showShareSheet = false

    enum ShareFormat {
        case text
        case markdown
        case both

        var title: String {
            switch self {
            case .text: return "Share as Text"
            case .markdown: return "Share as Markdown"
            case .both: return "Share"
            }
        }
    }

    var body: some View {
        Button(action: { showShareSheet = true }) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)

                if format != .both {
                    Text(format.title)
                        .font(.caption)
                }
            }
            .foregroundColor(.blue)
        }
        .sheet(isPresented: $showShareSheet) {
            if format == .both {
                ShareFormatPicker(answer: answer, question: question)
            } else {
                ShareSheet(items: shareItems)
            }
        }
    }

    private var shareItems: [Any] {
        switch format {
        case .text:
            return [ShareHelper.formatAsText(answer: answer, question: question)]
        case .markdown:
            return [ShareHelper.formatAsMarkdown(answer: answer, question: question)]
        case .both:
            // Default to text when both is selected (shouldn't reach here due to picker)
            return [ShareHelper.formatAsText(answer: answer, question: question)]
        }
    }
}

// MARK: - Share Format Picker

/// Allows user to choose share format
struct ShareFormatPicker: View {
    let answer: ContentAnswer
    let question: String?
    @Environment(\.dismiss) var dismiss
    @State private var showTextShare = false
    @State private var showMarkdownShare = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showTextShare = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Plain Text")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Share as simple text for easy copying")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button(action: {
                        showMarkdownShare = true
                    }) {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Markdown")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Share with formatting for notes apps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Choose Format")
                }
            }
            .navigationTitle("Share Answer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTextShare) {
            ShareSheet(items: [ShareHelper.formatAsText(answer: answer, question: question)])
        }
        .sheet(isPresented: $showMarkdownShare) {
            ShareSheet(items: [ShareHelper.formatAsMarkdown(answer: answer, question: question)])
        }
    }
}

// MARK: - Bookmarks Share Button

/// Share button specifically for bookmarks collection
struct BookmarksShareButton: View {
    let bookmarks: [Bookmark]
    @State private var showFormatPicker = false

    var body: some View {
        Button(action: { showFormatPicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                Text("Share All")
                    .font(.subheadline)
            }
        }
        .sheet(isPresented: $showFormatPicker) {
            BookmarksShareFormatPicker(bookmarks: bookmarks)
        }
    }
}

// MARK: - Bookmarks Share Format Picker

struct BookmarksShareFormatPicker: View {
    let bookmarks: [Bookmark]
    @Environment(\.dismiss) var dismiss
    @State private var showTextShare = false
    @State private var showMarkdownShare = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showTextShare = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Plain Text")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Share all \(bookmarks.count) bookmark\(bookmarks.count == 1 ? "" : "s") as text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button(action: {
                        showMarkdownShare = true
                    }) {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Markdown")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Share all \(bookmarks.count) bookmark\(bookmarks.count == 1 ? "" : "s") with formatting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Choose Format")
                }
            }
            .navigationTitle("Share Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTextShare) {
            ShareSheet(items: [ShareHelper.formatBookmarksAsText(bookmarks: bookmarks)])
        }
        .sheet(isPresented: $showMarkdownShare) {
            ShareSheet(items: [ShareHelper.formatBookmarksAsMarkdown(bookmarks: bookmarks)])
        }
    }
}
