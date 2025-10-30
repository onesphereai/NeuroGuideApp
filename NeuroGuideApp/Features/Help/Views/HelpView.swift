//
//  HelpView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System
//

import SwiftUI
import Combine

/// In-app help center with searchable FAQs
struct HelpView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = HelpViewModel()

    // MARK: - State

    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding()

                    if searchText.isEmpty {
                        // Category Browse
                        categoryBrowseView
                    } else {
                        // Search Results
                        searchResultsView
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        AccessibilityHelper.shared.buttonTap()
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Double tap to close help")
                    .accessibilityIdentifier("help_done_button")
                }
            }
        }
        .onAppear {
            AccessibilityHelper.announce("Help and support")
        }
    }

    // MARK: - Category Browse View

    private var categoryBrowseView: some View {
        VStack(spacing: 16) {
            ForEach(HelpArticle.HelpCategory.allCases, id: \.self) { category in
                CategorySection(
                    category: category,
                    articles: viewModel.articles(for: category)
                )
            }

            // Contact Support Card
            ContactSupportCard()
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .padding(.vertical)
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        VStack(spacing: 0) {
            let results = viewModel.search(query: searchText)

            if results.isEmpty {
                NoSearchResultsView(query: searchText)
                    .padding(.top, 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(results) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleRow(article: article, searchQuery: searchText)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if article.id != results.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: HelpArticle.HelpCategory
    let articles: [HelpArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorForCategory(category))
                    .frame(width: 28, height: 28)

                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(category.rawValue)

            // Articles
            VStack(spacing: 0) {
                ForEach(articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleRow(article: article)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if article.id != articles.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func iconForCategory(_ category: HelpArticle.HelpCategory) -> String {
        switch category {
        case .gettingStarted: return "flag.fill"
        case .sessions: return "bubble.left.and.bubble.right.fill"
        case .childProfiles: return "person.fill"
        case .accessibility: return "accessibility"
        case .privacy: return "lock.fill"
        case .troubleshooting: return "wrench.and.screwdriver.fill"
        }
    }

    private func colorForCategory(_ category: HelpArticle.HelpCategory) -> Color {
        switch category {
        case .gettingStarted: return .green
        case .sessions: return .blue
        case .childProfiles: return .purple
        case .accessibility: return .orange
        case .privacy: return .green
        case .troubleshooting: return .red
        }
    }
}

// MARK: - Article Row

struct ArticleRow: View {
    let article: HelpArticle
    var searchQuery: String = ""

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .accessibilityLabel(article.title)

                if !searchQuery.isEmpty {
                    Text(article.content.prefix(100) + "...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to read full article")
    }
}

// MARK: - Article Detail View

struct ArticleDetailView: View {
    let article: HelpArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Category Badge
                HStack {
                    Text(article.category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(12)

                    Spacer()
                }
                .accessibilityLabel("Category: \(article.category.rawValue)")

                // Content
                Text(article.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .accessibilityLabel(article.content)
            }
            .padding()
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            AccessibilityHelper.announce(article.title)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            TextField("Search help articles...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityLabel("Search help articles")
                .accessibilityIdentifier("help_search_field")

            if !text.isEmpty {
                Button(action: {
                    AccessibilityHelper.shared.buttonTap()
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityIdentifier("help_clear_search_button")
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - No Search Results

struct NoSearchResultsView: View {
    let query: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No results for \"\(query)\"")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Try different keywords or browse by category")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No results found for \(query). Try different keywords or browse by category")
    }
}

// MARK: - Contact Support Card

struct ContactSupportCard: View {
    var body: some View {
        NavigationLink(destination: SupportView()) {
            HStack(spacing: 16) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Still need help?")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Contact our support team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Contact support")
        .accessibilityHint("Double tap to open contact form")
    }
}

// MARK: - Help View Model

class HelpViewModel: ObservableObject {
    @Published var allArticles: [HelpArticle] = HelpArticle.defaultArticles

    func articles(for category: HelpArticle.HelpCategory) -> [HelpArticle] {
        return allArticles.filter { $0.category == category }
    }

    func search(query: String) -> [HelpArticle] {
        let lowercasedQuery = query.lowercased()

        return allArticles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            article.content.lowercased().contains(lowercasedQuery) ||
            article.keywords.contains { $0.contains(lowercasedQuery) }
        }
    }
}

// MARK: - Preview

#Preview {
    HelpView()
}
