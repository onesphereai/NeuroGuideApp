//
//  OnboardingView.swift
//  NeuroGuide
//
//  Created by AI-DLC on 2025-10-20.
//  Bolt 1.2 - Onboarding & Tutorial
//

import SwiftUI

/// Main onboarding tutorial view with page navigation
struct OnboardingView: View {

    // MARK: - Properties

    @StateObject var viewModel: OnboardingViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Branded background
            Color.ngBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (top-right)
                HStack {
                    Spacer()
                    Button("Skip") {
                        viewModel.skipOnboarding()
                    }
                    .font(.ngCallout)
                    .foregroundColor(.ngPrimaryBlue)
                    .padding(NGSpacing.md)
                    .accessibilityLabel("Skip tutorial")
                    .accessibilityHint("Double tap to skip the tutorial and go to home screen")
                }

                // Progress indicator
                OnboardingProgressView(
                    currentPage: viewModel.currentPageIndex,
                    totalPages: viewModel.pages.count
                )
                .padding(.vertical, NGSpacing.md)

                // Page content
                TabView(selection: $viewModel.currentPageIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Hide default dots
                .indexViewStyle(.page(backgroundDisplayMode: .never))

                // Navigation buttons
                HStack(spacing: NGSpacing.md) {
                    // Back button
                    if viewModel.canGoBack {
                        Button(action: {
                            viewModel.previousPage()
                        }) {
                            HStack(spacing: NGSpacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(.ngBodySemibold)
                                Text("Back")
                                    .font(.ngBodySemibold)
                            }
                            .foregroundColor(.ngTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.ngSurface)
                            .cornerRadius(NGRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: NGRadius.lg)
                                    .stroke(Color.ngBorder, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Previous page")
                        .accessibilityHint("Double tap to go back to the previous page")
                    }

                    // Next/Get Started button
                    Button(action: {
                        if viewModel.isLastPage {
                            viewModel.completeOnboarding()
                        } else {
                            viewModel.nextPage()
                        }
                    }) {
                        HStack(spacing: NGSpacing.xs) {
                            Text(viewModel.isLastPage ? "Get Started" : "Next")
                                .font(.ngBodySemibold)
                            if !viewModel.isLastPage {
                                Image(systemName: "chevron.right")
                                    .font(.ngBodySemibold)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.ngBodySemibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.ngPrimaryBlue, Color.ngSecondaryPurple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(NGRadius.lg)
                        .shadow(color: Color.ngPrimaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityLabel(viewModel.isLastPage ? "Get started" : "Next page")
                    .accessibilityHint(viewModel.isLastPage ? "Double tap to complete the tutorial and go to home screen" : "Double tap to go to the next page")
                }
                .padding(.horizontal, NGSpacing.md)
                .padding(.bottom, NGSpacing.xl)
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            // Announce initial page
            if let page = viewModel.currentPage {
                AccessibilityHelper.announce("Tutorial started. Page 1 of \(viewModel.pages.count). \(page.title)")
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding - First Page") {
    OnboardingView(viewModel: OnboardingViewModel())
}

#Preview("Onboarding - With Coordinator") {
    let coordinator = AppCoordinator()
    let viewModel = OnboardingViewModel(coordinator: coordinator)
    return OnboardingView(viewModel: viewModel)
}
