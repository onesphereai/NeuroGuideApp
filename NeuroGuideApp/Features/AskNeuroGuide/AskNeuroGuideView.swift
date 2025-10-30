//
//  AskNeuroGuideView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import SwiftUI

/// Main view for conversational Q&A with NeuroGuide
/// Supports both voice and text input
struct AskNeuroGuideView: View {
    @StateObject private var viewModel = AskNeuroGuideViewModel()
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var historyManager = SearchHistoryManager.shared
    @State private var showErrorAlert = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @State private var showBookmarks = false
    @State private var showHistory = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Conversation history
                if viewModel.conversationTurns.isEmpty {
                    emptyState
                } else {
                    conversationList
                }

                Divider()

                // Input area
                questionInputArea
            }
            .navigationTitle("Ask attune")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // History button
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock")
                            .font(.body)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showBookmarks = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bookmark")
                                .font(.body)

                            // Badge showing bookmark count
                            if bookmarkManager.bookmarks.count > 0 {
                                Text("\(bookmarkManager.bookmarks.count)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .alert(errorAlertTitle, isPresented: $showErrorAlert) {
                if errorAlertTitle == "Permission Required" {
                    Button("Settings", action: openSettings)
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorAlertMessage)
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarksView()
            }
            .sheet(isPresented: $showHistory) {
                SearchHistoryView(onSearchTap: { query in
                    showHistory = false
                    viewModel.textInput = query
                    Task {
                        await viewModel.submitTextQuestion()
                    }
                })
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                VStack(spacing: 12) {
                    Text("Ask attune")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Get expert guidance on neurodiversity-affirming parenting")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Recent searches if available
                if !historyManager.history.isEmpty {
                    RecentSearchesView(
                        onSearchTap: { query in
                            viewModel.textInput = query
                            Task {
                                await viewModel.submitTextQuestion()
                            }
                        },
                        limit: 3
                    )
                    .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 12) {
                    exampleQuestion(icon: "face.smiling", text: "How do I support my child during meltdowns?")
                    exampleQuestion(icon: "ear.fill", text: "What are sensory-friendly activities?")
                    exampleQuestion(icon: "heart.fill", text: "How can I celebrate my child's stims?")
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)
            }
        }
    }

    private func exampleQuestion(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.conversationTurns) { turn in
                        ConversationTurnView(turn: turn)
                            .id(turn.id)
                    }

                    // Suggested follow-up questions
                    if !viewModel.suggestedQuestions.isEmpty {
                        SuggestedQuestionsView(
                            questions: viewModel.suggestedQuestions,
                            onQuestionTap: { question in
                                handleSuggestedQuestionTap(question)
                            }
                        )
                        .id("suggestions")
                    }

                    // Related questions
                    if !viewModel.relatedQuestions.isEmpty {
                        RelatedQuestionsView(
                            questions: viewModel.relatedQuestions,
                            onQuestionTap: { question in
                                handleSuggestedQuestionTap(question)
                            }
                        )
                        .id("related")
                    }
                }
                .padding()
                .onChange(of: viewModel.conversationTurns.count) { _ in
                    if let lastTurn = viewModel.conversationTurns.last {
                        withAnimation {
                            proxy.scrollTo(lastTurn.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Question Input Area

    private var questionInputArea: some View {
        VStack(spacing: 12) {
            // Text input field
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $viewModel.textInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isProcessing)

                // Send text button
                Button(action: {
                    Task {
                        await viewModel.submitTextQuestion()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.textInput.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.textInput.isEmpty || viewModel.isProcessing)
            }

            // Voice input button
            Button(action: {
                Task {
                    await handleVoiceInput()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)

                    if viewModel.isRecording {
                        Text("Tap to stop recording")
                            .font(.subheadline)

                        // Animated recording indicator
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(viewModel.recordingPulseAnimation ? 1.0 : 0.3)
                    } else {
                        Text("Ask by voice")
                            .font(.subheadline)
                    }

                    Spacer()
                }
                .padding()
                .background(viewModel.isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(viewModel.isProcessing && !viewModel.isRecording)

            // Recognized text preview
            if !viewModel.recognizedText.isEmpty && viewModel.isRecording {
                HStack {
                    Text(viewModel.recognizedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal)
            }

            // Processing indicator
            if viewModel.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Clear conversation button
            if !viewModel.conversationTurns.isEmpty {
                Button(action: {
                    viewModel.clearConversation()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Clear conversation")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Actions

    private func handleVoiceInput() async {
        do {
            if viewModel.isRecording {
                try await viewModel.stopVoiceRecording()
            } else {
                try await viewModel.startVoiceRecording()
            }
        } catch let error as QuestionInputError {
            // Handle specific QuestionInputError types
            switch error {
            case .microphonePermissionDenied, .speechRecognitionPermissionDenied:
                errorAlertTitle = "Permission Required"
                errorAlertMessage = error.localizedDescription
            case .noSpeechDetected:
                errorAlertTitle = "No Speech Detected"
                errorAlertMessage = "Please try again and speak clearly after tapping the microphone button."
            default:
                errorAlertTitle = "Voice Input Error"
                errorAlertMessage = error.localizedDescription
            }
            showErrorAlert = true
        } catch {
            // Handle other errors
            errorAlertTitle = "Error"
            errorAlertMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func handleSuggestedQuestionTap(_ question: String) {
        // Set the question as text input
        viewModel.textInput = question

        // Submit the question
        Task {
            await viewModel.submitTextQuestion()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Conversation Turn View

struct ConversationTurnView: View {
    let turn: ConversationTurn

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: turn.question.inputMethod.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(turn.question.text)
                        .font(.body)
                        .fontWeight(.medium)

                    Text(formatTimestamp(turn.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)

            // Answers
            if turn.result.answers.isEmpty {
                noResultsView
            } else {
                ForEach(turn.result.answers) { answer in
                    AnswerCardView(answer: answer, question: turn.question.text)
                }
            }
        }
    }

    private var noResultsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.orange)

            Text("No results found. Try rephrasing your question.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Answer Card View

struct AnswerCardView: View {
    let answer: ContentAnswer
    let question: String
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var isExpanded = true
    @State private var showSourceDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Source header with credibility badge
            HStack(spacing: 8) {
                CredibilityBadge(level: answer.source.credibilityLevel, compact: true)

                Text(answer.source.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                // Relevance score
                Text("\(answer.relevancePercentage)% match")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Share button
                ShareButton(answer: answer, question: question, format: .both)

                // Bookmark button
                Button(action: {
                    bookmarkManager.toggleBookmark(answer: answer, question: question)
                }) {
                    Image(systemName: bookmarkManager.isBookmarked(answerId: answer.id) ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundColor(bookmarkManager.isBookmarked(answerId: answer.id) ? .orange : .gray)
                }

                // Info button to show source details
                Button(action: {
                    showSourceDetails = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            // Author information if available
            if let author = answer.source.author {
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
                Text(answer.content)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                // Strategies (if any)
                if let strategies = answer.strategies, !strategies.isEmpty {
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

                // Resource Citations (from LLM responses)
                if let citations = answer.resourceCitations, !citations.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Learn More")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(citations) { citation in
                            if let url = URL(string: citation.url) {
                                Link(destination: url) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "book.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(citation.title)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)

                                            if let description = citation.description {
                                                Text(description)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.up.right")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(10)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                // Feedback buttons
                Divider()

                FeedbackButtons(answer: answer, questionText: question)
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
            SourceDetailsSheet(source: answer.source)
        }
    }
}

// MARK: - Preview

#Preview {
    AskNeuroGuideView()
}
