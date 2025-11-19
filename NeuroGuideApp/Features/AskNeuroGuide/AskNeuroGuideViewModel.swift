//
//  AskNeuroGuideViewModel.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-27.
//  Unit 7 - Ask NeuroGuide
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for Ask NeuroGuide conversational interface
@MainActor
class AskNeuroGuideViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var textInput = ""
    @Published private(set) var isRecording = false
    @Published private(set) var recognizedText = ""
    @Published private(set) var isProcessing = false
    @Published private(set) var conversationTurns: [ConversationTurn] = []
    @Published private(set) var currentContext: ConversationContext?
    @Published var recordingPulseAnimation = false
    @Published private(set) var suggestedQuestions: [String] = []
    @Published private(set) var relatedQuestions: [String] = []

    // MARK: - Private Properties

    private let questionInputManager: QuestionInputManager
    private let searchManager: ConversationalSearchManager
    private let followUpGenerator: FollowUpQuestionGenerator
    private let relatedQuestionEngine: RelatedQuestionEngine
    private let historyManager: SearchHistoryManager
    private let profileManager: ChildProfileService
    private var cancellables = Set<AnyCancellable>()
    nonisolated(unsafe) private var pulseTimer: Timer?

    private var currentProfile: ChildProfile?

    // MARK: - Initialization

    init(
        questionInputManager: QuestionInputManager = .shared,
        searchManager: ConversationalSearchManager = .shared,
        followUpGenerator: FollowUpQuestionGenerator = FollowUpQuestionGenerator(),
        relatedQuestionEngine: RelatedQuestionEngine = RelatedQuestionEngine(),
        historyManager: SearchHistoryManager = .shared,
        profileManager: ChildProfileService = ChildProfileManager.shared
    ) {
        self.questionInputManager = questionInputManager
        self.searchManager = searchManager
        self.followUpGenerator = followUpGenerator
        self.relatedQuestionEngine = relatedQuestionEngine
        self.historyManager = historyManager
        self.profileManager = profileManager

        // Load current profile
        Task {
            await loadCurrentProfile()
        }

        // Observe recording state
        questionInputManager.$isRecording
            .assign(to: &$isRecording)

        questionInputManager.$recognizedText
            .assign(to: &$recognizedText)

        // Start pulse animation when recording
        $isRecording
            .sink { [weak self] recording in
                if recording {
                    self?.startPulseAnimation()
                } else {
                    self?.stopPulseAnimation()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Voice Input

    /// Start voice recording
    func startVoiceRecording() async throws {
        try await questionInputManager.startVoiceRecording()
    }

    /// Stop voice recording and submit question
    func stopVoiceRecording() async throws {
        isProcessing = true
        defer { isProcessing = false }

        let transcribedText = try await questionInputManager.stopVoiceRecording()

        // Create voice question
        let question = Question(
            text: transcribedText,
            inputMethod: .voice
        )

        // Search for answer
        await performSearch(for: question)
    }

    // MARK: - Text Input

    /// Submit text question
    func submitTextQuestion() async {
        guard !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let question = try await questionInputManager.submitTextQuestion(
                text: textInput,
                childID: currentProfile?.id
            )

            // Clear input
            textInput = ""

            // Search for answer with profile context
            await performSearch(for: question)
        } catch {
            print("❌ Failed to submit text question: \(error)")
        }
    }

    // MARK: - Search

    /// Perform search for question
    private func performSearch(for question: Question) async {
        do {
            // Use real search service with profile context
            let result = try await searchManager.search(
                query: question,
                context: currentContext,
                profile: currentProfile
            )

            // Create conversation turn
            let turn = ConversationTurn(
                question: question,
                result: result
            )

            // Add to conversation
            conversationTurns.append(turn)

            // Update context
            if let context = currentContext {
                currentContext = context.addingTurn(turn)
            } else {
                currentContext = ConversationContext(
                    turns: [turn],
                    topics: []
                )
            }

            // Generate suggested follow-up questions
            if let context = currentContext {
                suggestedQuestions = followUpGenerator.generateContextualFollowUps(
                    for: context,
                    currentResult: result,
                    limit: 3
                )
            } else {
                suggestedQuestions = followUpGenerator.generateFollowUps(
                    for: result,
                    limit: 3
                )
            }

            // Generate related questions
            relatedQuestions = relatedQuestionEngine.generateRelatedQuestions(
                for: result,
                limit: 3
            )

            // Add to search history
            historyManager.addSearch(query: question.text, answerCount: result.answers.count)

            print("✅ Added conversation turn: \(question.text) with \(result.answers.count) answers")
            print("💡 Generated \(suggestedQuestions.count) follow-up suggestions")
            print("🔗 Generated \(relatedQuestions.count) related questions")
        } catch {
            print("❌ Search failed: \(error)")

            // Create error result
            let errorAnswer = ContentAnswer(
                content: "Sorry, I couldn't find an answer to your question. Please try rephrasing it or ask something else.",
                source: ContentSource(
                    title: "Attune",
                    section: nil,
                    author: nil,
                    credibilityLevel: .communityValidated
                ),
                relevanceScore: 0.0,
                strategies: nil
            )

            let errorResult = SearchResult(
                query: question,
                answers: [errorAnswer],
                conversationContext: currentContext
            )

            let turn = ConversationTurn(
                question: question,
                result: errorResult
            )

            conversationTurns.append(turn)
        }
    }

    // MARK: - Conversation Management

    /// Clear conversation history
    func clearConversation() {
        conversationTurns.removeAll()
        currentContext = nil
        searchManager.clearConversation()
        print("🗑️ Conversation cleared")
    }

    // MARK: - Animation

    private func startPulseAnimation() {
        recordingPulseAnimation = false
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                self?.recordingPulseAnimation.toggle()
            }
        }
        pulseTimer?.fire()
    }

    private func stopPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        recordingPulseAnimation = false
    }

    nonisolated private func cleanup() {
        pulseTimer?.invalidate()
    }

    // MARK: - Profile Management

    /// Load current child profile
    private func loadCurrentProfile() async {
        do {
            currentProfile = try await profileManager.getProfile()
            if let profile = currentProfile {
                print("✅ Loaded profile for Ask Attune: \(profile.name)")
            }
        } catch {
            print("❌ Failed to load profile: \(error)")
        }
    }

    deinit {
        cleanup()
    }
}
