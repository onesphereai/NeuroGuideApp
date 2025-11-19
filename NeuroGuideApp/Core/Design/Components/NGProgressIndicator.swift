//
//  NGProgressIndicator.swift
//  NeuroGuide
//
//  Created for AT-41: Co-Regulation Pagination
//  Progress indicator component showing "X/Y" format
//

import SwiftUI

/// Progress indicator displaying current step and total (e.g., "1/10")
struct NGProgressIndicator: View {
    let current: Int
    let total: Int
    let style: ProgressIndicatorStyle

    init(current: Int, total: Int, style: ProgressIndicatorStyle = .default) {
        self.current = current
        self.total = total
        self.style = style
    }

    var body: some View {
        HStack(spacing: NGSpacing.xs) {
            if style.showIcon {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: style.iconSize))
                    .foregroundColor(style.textColor)
            }

            Text("\(current)")
                .font(style.numberFont)
                .fontWeight(.bold)
                .foregroundColor(style.currentNumberColor)

            Text("/")
                .font(style.separatorFont)
                .foregroundColor(style.separatorColor)

            Text("\(total)")
                .font(style.numberFont)
                .foregroundColor(style.totalNumberColor)
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, style.verticalPadding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(current) of \(total)")
        .accessibilityValue(progressPercentage)
    }

    private var progressPercentage: String {
        let percentage = Int((Double(current) / Double(total)) * 100)
        return "\(percentage)% complete"
    }
}

// MARK: - Progress Indicator Style

struct ProgressIndicatorStyle {
    let numberFont: Font
    let separatorFont: Font
    let currentNumberColor: Color
    let totalNumberColor: Color
    let separatorColor: Color
    let textColor: Color
    let backgroundColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let cornerRadius: CGFloat
    let showIcon: Bool
    let iconSize: CGFloat

    /// Default style - compact and clean
    static let `default` = ProgressIndicatorStyle(
        numberFont: .ngTitle3,
        separatorFont: .ngTitle3,
        currentNumberColor: .ngPrimaryBlue,
        totalNumberColor: .ngTextSecondary,
        separatorColor: .ngTextSecondary,
        textColor: .ngTextSecondary,
        backgroundColor: Color(.systemGray6),
        horizontalPadding: NGSpacing.md,
        verticalPadding: NGSpacing.sm,
        cornerRadius: NGRadius.full,
        showIcon: false,
        iconSize: 16
    )

    /// Large style - more prominent for key flows
    static let large = ProgressIndicatorStyle(
        numberFont: .ngTitle2,
        separatorFont: .ngTitle2,
        currentNumberColor: .ngPrimaryBlue,
        totalNumberColor: .ngTextSecondary,
        separatorColor: .ngTextSecondary,
        textColor: .ngTextSecondary,
        backgroundColor: Color(.systemGray6),
        horizontalPadding: NGSpacing.lg,
        verticalPadding: NGSpacing.md,
        cornerRadius: NGRadius.full,
        showIcon: false,
        iconSize: 20
    )

    /// Minimal style - just the numbers
    static let minimal = ProgressIndicatorStyle(
        numberFont: .ngCallout,
        separatorFont: .ngCallout,
        currentNumberColor: .ngPrimaryBlue,
        totalNumberColor: .ngTextSecondary,
        separatorColor: .ngTextSecondary,
        textColor: .ngTextSecondary,
        backgroundColor: .clear,
        horizontalPadding: 0,
        verticalPadding: 0,
        cornerRadius: 0,
        showIcon: false,
        iconSize: 14
    )

    /// With icon - includes progress icon
    static let withIcon = ProgressIndicatorStyle(
        numberFont: .ngTitle3,
        separatorFont: .ngTitle3,
        currentNumberColor: .ngPrimaryBlue,
        totalNumberColor: .ngTextSecondary,
        separatorColor: .ngTextSecondary,
        textColor: .ngTextSecondary,
        backgroundColor: Color(.systemGray6),
        horizontalPadding: NGSpacing.md,
        verticalPadding: NGSpacing.sm,
        cornerRadius: NGRadius.full,
        showIcon: true,
        iconSize: 16
    )
}

// MARK: - Convenience Initializers

extension NGProgressIndicator {
    /// Create progress indicator from CoRegulationQuestion
    init(question: CoRegulationQuestion, style: ProgressIndicatorStyle = .default) {
        self.current = question.rawValue
        self.total = CoRegulationQuestion.totalCount
        self.style = style
    }
}

// MARK: - Previews

#Preview("Progress Indicator Styles") {
    ScrollView {
        VStack(spacing: NGSpacing.xl) {
            VStack(alignment: .leading, spacing: NGSpacing.md) {
                Text("Default Style")
                    .font(.ngTitle3)
                NGProgressIndicator(current: 3, total: 10)
            }

            VStack(alignment: .leading, spacing: NGSpacing.md) {
                Text("Large Style")
                    .font(.ngTitle3)
                NGProgressIndicator(current: 3, total: 10, style: .large)
            }

            VStack(alignment: .leading, spacing: NGSpacing.md) {
                Text("Minimal Style")
                    .font(.ngTitle3)
                NGProgressIndicator(current: 3, total: 10, style: .minimal)
            }

            VStack(alignment: .leading, spacing: NGSpacing.md) {
                Text("With Icon Style")
                    .font(.ngTitle3)
                NGProgressIndicator(current: 3, total: 10, style: .withIcon)
            }

            VStack(alignment: .leading, spacing: NGSpacing.md) {
                Text("Progress Sequence")
                    .font(.ngTitle3)
                ForEach(1...10, id: \.self) { step in
                    NGProgressIndicator(current: step, total: 10)
                }
            }
        }
        .padding()
    }
}
