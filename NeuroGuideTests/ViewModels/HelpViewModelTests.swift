//
//  HelpViewModelTests.swift
//  NeuroGuideTests
//
//  Created by AI-DLC on 2025-10-22.
//  Bolt 1.3 - Settings & Help System Tests
//

import XCTest
@testable import NeuroGuideApp

final class HelpViewModelTests: XCTestCase {

    var viewModel: HelpViewModel!

    override func setUp() {
        super.setUp()
        viewModel = HelpViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.allArticles.isEmpty)
        XCTAssertEqual(viewModel.allArticles.count, HelpArticle.defaultArticles.count)
    }

    // MARK: - Articles By Category Tests

    func testArticlesForGettingStarted() {
        let articles = viewModel.articles(for: .gettingStarted)
        XCTAssertFalse(articles.isEmpty)
        XCTAssertTrue(articles.allSatisfy { $0.category == .gettingStarted })
    }

    func testArticlesForSessions() {
        let articles = viewModel.articles(for: .sessions)
        XCTAssertFalse(articles.isEmpty)
        XCTAssertTrue(articles.allSatisfy { $0.category == .sessions })
    }

    func testArticlesForAccessibility() {
        let articles = viewModel.articles(for: .accessibility)
        XCTAssertFalse(articles.isEmpty)
        XCTAssertTrue(articles.allSatisfy { $0.category == .accessibility })
    }

    func testAllCategoriesHaveArticles() {
        for category in HelpArticle.HelpCategory.allCases {
            let articles = viewModel.articles(for: category)
            XCTAssertFalse(articles.isEmpty, "Category \(category.rawValue) should have articles")
        }
    }

    // MARK: - Search Tests

    func testSearchByTitle() {
        let results = viewModel.search(query: "VoiceOver")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.title.contains("VoiceOver") })
    }

    func testSearchByContent() {
        let results = viewModel.search(query: "session")
        XCTAssertFalse(results.isEmpty)
    }

    func testSearchByKeyword() {
        let results = viewModel.search(query: "accessibility")
        XCTAssertFalse(results.isEmpty)
    }

    func testSearchCaseInsensitive() {
        let lowercaseResults = viewModel.search(query: "voiceover")
        let uppercaseResults = viewModel.search(query: "VOICEOVER")
        let mixedResults = viewModel.search(query: "VoiceOver")

        XCTAssertFalse(lowercaseResults.isEmpty)
        XCTAssertEqual(lowercaseResults.count, uppercaseResults.count)
        XCTAssertEqual(lowercaseResults.count, mixedResults.count)
    }

    func testSearchNoResults() {
        let results = viewModel.search(query: "xyznonexistent")
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchEmptyQuery() {
        let results = viewModel.search(query: "")
        // Empty query should return all articles
        XCTAssertEqual(results.count, viewModel.allArticles.count)
    }

    func testSearchPartialMatch() {
        let results = viewModel.search(query: "crisi")
        XCTAssertFalse(results.isEmpty, "Should find articles with 'crisis'")
    }
}

// MARK: - HelpArticle Tests

final class HelpArticleTests: XCTestCase {

    // MARK: - Default Articles Tests

    func testDefaultArticlesExist() {
        let articles = HelpArticle.defaultArticles
        XCTAssertFalse(articles.isEmpty)
        XCTAssertGreaterThanOrEqual(articles.count, 10)
    }

    func testUniqueArticleIDs() {
        let articles = HelpArticle.defaultArticles
        let ids = articles.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All article IDs should be unique")
    }

    func testAllArticlesHaveContent() {
        let articles = HelpArticle.defaultArticles

        for article in articles {
            XCTAssertFalse(article.title.isEmpty, "Article \(article.id) should have a title")
            XCTAssertFalse(article.content.isEmpty, "Article \(article.id) should have content")
            XCTAssertFalse(article.keywords.isEmpty, "Article \(article.id) should have keywords")
        }
    }

    // MARK: - Category Tests

    func testCategoryRawValues() {
        XCTAssertEqual(HelpArticle.HelpCategory.gettingStarted.rawValue, "Getting Started")
        XCTAssertEqual(HelpArticle.HelpCategory.sessions.rawValue, "Using Sessions")
        XCTAssertEqual(HelpArticle.HelpCategory.childProfiles.rawValue, "Child Profiles")
        XCTAssertEqual(HelpArticle.HelpCategory.accessibility.rawValue, "Accessibility")
        XCTAssertEqual(HelpArticle.HelpCategory.privacy.rawValue, "Privacy & Data")
        XCTAssertEqual(HelpArticle.HelpCategory.troubleshooting.rawValue, "Troubleshooting")
    }

    func testAllCategoriesAreUsed() {
        let articles = HelpArticle.defaultArticles
        let usedCategories = Set(articles.map { $0.category })

        for category in HelpArticle.HelpCategory.allCases {
            XCTAssertTrue(usedCategories.contains(category),
                         "Category \(category.rawValue) should be used by at least one article")
        }
    }

    // MARK: - Specific Article Tests

    func testWelcomeArticle() {
        let article = HelpArticle.defaultArticles.first { $0.id == "welcome" }
        XCTAssertNotNil(article)
        XCTAssertEqual(article?.category, .gettingStarted)
        XCTAssertTrue(article?.keywords.contains("welcome") ?? false)
    }

    func testVoiceOverArticle() {
        let article = HelpArticle.defaultArticles.first { $0.id == "voiceover" }
        XCTAssertNotNil(article)
        XCTAssertEqual(article?.category, .accessibility)
        XCTAssertTrue(article?.title.contains("VoiceOver") ?? false)
    }

    func testPrivacyArticle() {
        let article = HelpArticle.defaultArticles.first { $0.id == "data-privacy" }
        XCTAssertNotNil(article)
        XCTAssertEqual(article?.category, .privacy)
        XCTAssertTrue(article?.content.contains("privacy") ?? false)
    }

    // MARK: - Hashable/Equatable Tests

    func testArticleEquality() {
        let article1 = HelpArticle(
            id: "test1",
            title: "Test Article",
            content: "Content",
            category: .gettingStarted,
            keywords: ["test"]
        )

        let article2 = HelpArticle(
            id: "test1",
            title: "Test Article",
            content: "Content",
            category: .gettingStarted,
            keywords: ["test"]
        )

        XCTAssertEqual(article1, article2)
    }

    func testArticleInequality() {
        let article1 = HelpArticle(
            id: "test1",
            title: "Test Article 1",
            content: "Content",
            category: .gettingStarted,
            keywords: ["test"]
        )

        let article2 = HelpArticle(
            id: "test2",
            title: "Test Article 2",
            content: "Content",
            category: .gettingStarted,
            keywords: ["test"]
        )

        XCTAssertNotEqual(article1, article2)
    }

    func testArticleHashable() {
        let article1 = HelpArticle(
            id: "test1",
            title: "Test Article",
            content: "Content",
            category: .gettingStarted,
            keywords: ["test"]
        )

        let article2 = HelpArticle(
            id: "test1",
            title: "Test Article",
            content: "Content",
            category: .gettingStarted,
            keywords: ["test"]
        )

        let set: Set<HelpArticle> = [article1, article2]
        XCTAssertEqual(set.count, 1, "Identical articles should hash to the same value")
    }

    // MARK: - Content Quality Tests

    func testArticlesHaveSubstantialContent() {
        let articles = HelpArticle.defaultArticles

        for article in articles {
            XCTAssertGreaterThan(article.content.count, 50,
                               "Article \(article.id) should have substantial content")
        }
    }

    func testKeywordsAreRelevant() {
        let articles = HelpArticle.defaultArticles

        for article in articles {
            for keyword in article.keywords {
                let titleContains = article.title.lowercased().contains(keyword.lowercased())
                let contentContains = article.content.lowercased().contains(keyword.lowercased())

                XCTAssertTrue(titleContains || contentContains,
                            "Keyword '\(keyword)' in article '\(article.id)' should appear in title or content")
            }
        }
    }
}
