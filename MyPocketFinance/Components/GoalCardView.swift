import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    var animationDelay: Double = 0
    var showsOverviewLabel: Bool = false

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var animatedProgress: Double = 0
    @State private var isCelebratingCompletion: Bool = false

    private enum ScheduleStatus {
        case noDeadline
        case onTrack
        case behind
        case completed
    }

    private var progressPercentageText: String {
        let percentage = Int(goal.progress * 100)
        return "\(percentage)%"
    }

    private var timeProgress: Double? {
        guard let dueDate = goal.dueDate,
              dueDate > goal.createdAt
        else { return nil }

        let total = dueDate.timeIntervalSince(goal.createdAt)
        let elapsed = Date().timeIntervalSince(goal.createdAt)
        guard total > 0 else { return nil }

        let fraction = elapsed / total
        return min(max(fraction, 0), 1)
    }

    private var scheduleStatus: ScheduleStatus {
        if goal.progress >= 1.0 {
            return .completed
        }
        guard let timeProgress else { return .noDeadline }

        if goal.progress >= max(timeProgress * 0.9, 0) {
            return .onTrack
        } else {
            return .behind
        }
    }

    private var statusBadgeText: String {
        switch scheduleStatus {
        case .completed:
            return "Completed"
        case .onTrack:
            return "On track"
        case .behind:
            return "Behind"
        case .noDeadline:
            return "No deadline"
        }
    }

    private var statusBadgeColor: Color {
        switch scheduleStatus {
        case .completed:
            return colors.success
        case .onTrack:
            return colors.primary
        case .behind:
            return colors.warning
        case .noDeadline:
            return colors.textSecondary
        }
    }

    private var scheduleSubtitleText: String {
        guard let dueDate = goal.dueDate else {
            return "No target date"
        }

        let calendar = Calendar.current
        let now = Date()
        guard let days = calendar.dateComponents([.day], from: now, to: dueDate).day else {
            return "Until \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        }

        let prefix: String
        switch scheduleStatus {
        case .completed:
            return "Goal completed"
        case .onTrack:
            prefix = "On track"
        case .behind:
            prefix = "Behind schedule"
        case .noDeadline:
            return "No target date"
        }

        if days <= 0 {
            return "\(prefix) – deadline today"
        } else if days < 7 {
            return "\(prefix) – ~\(days) days left"
        } else {
            let weeks = Int(ceil(Double(days) / 7.0))
            return "\(prefix) – ~\(weeks) weeks left"
        }
    }

    private var progressGradientColors: [Color] {
        let p = goal.progress
        switch p {
        case ..<0.34:
            return [
                colors.secondary.opacity(0.8),
                colors.secondary
            ]
        case ..<0.67:
            return colors.primaryGradientColors
        case ..<1.0:
            return [
                colors.success,
                colors.success.opacity(0.9)
            ]
        default:
            return [
                colors.success,
                colors.success.opacity(0.9)
            ]
        }
    }

    private var progressAccentColor: Color {
        progressGradientColors.last ?? colors.primary
    }

    private func categoryIconName(for category: GoalCategory) -> String {
        switch category {
        case .savings: return "banknote.fill"
        case .travel: return "airplane"
        case .emergency: return "shield.lefthalf.filled"
        case .education: return "book.fill"
        case .lifestyle: return "sparkles"
        case .other: return "ellipsis.circle"
        }
    }

    var body: some View {
        ZStack {
        VStack(alignment: .leading, spacing: spacing.m) {
            HStack(alignment: .top, spacing: spacing.m) {
                VStack(alignment: .leading, spacing: spacing.xs) {
                    if showsOverviewLabel {
                        Text("Goal overview")
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }

                    Text(goal.name)
                        .font(showsOverviewLabel ? typography.body.weight(.semibold) : typography.subtitle)
                        .foregroundStyle(colors.textPrimary)

                    Text("Target \(goal.targetAmount.appCurrencyString(code: goal.currency.rawValue))")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    Text(statusBadgeText)
                        .font(typography.caption)
                        .padding(.horizontal, spacing.s)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(statusBadgeColor.opacity(0.10))
                        )
                        .foregroundStyle(statusBadgeColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: spacing.xs) {
                    HStack(spacing: spacing.xs) {
                        Image(systemName: categoryIconName(for: goal.category))
                            .font(.system(size: 11, weight: .semibold))

                        Text(goal.category.title)
                            .font(typography.caption)
                    }
                    .padding(.horizontal, spacing.s)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colors.card.opacity(0.9))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(colors.subtleBorder, lineWidth: 1)
                    )
                    .foregroundStyle(colors.textSecondary)

                    Text(progressPercentageText)
                        .font(typography.caption)
                        .padding(.horizontal, spacing.s)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(progressAccentColor.opacity(0.14))
                        )
                        .foregroundStyle(progressAccentColor)
                }
            }

            VStack(alignment: .leading, spacing: spacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(colors.card.opacity(0.9))

                        if let timeProgress {
                            RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                                .fill(colors.subtleBorder.opacity(0.7))
                                .frame(width: geometry.size.width * timeProgress)
                        }

                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: progressGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * animatedProgress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(goal.currentAmount.appCurrencyString(code: goal.currency.rawValue))
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Text(scheduleSubtitleText)
                            .font(typography.caption)
                    }
                    .foregroundStyle(colors.textSecondary)
                }
            }
        }
        .padding(spacing.m)
        .background(
            LinearGradient(
                colors: [
                    colors.card,
                    colors.card.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius.l,
                style: .continuous
            )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 10)
        .scaleEffect(isCelebratingCompletion ? 1.04 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCelebratingCompletion)
        .onAppear {
            withAnimation(
                .spring(response: 0.7, dampingFraction: 0.85, blendDuration: 0.2)
                .delay(animationDelay)
            ) {
                animatedProgress = goal.progress
            }
        }
        .onChange(of: goal.progress, initial: false) { oldValue, newValue in
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0.2)
            ) {
                animatedProgress = newValue
            }

            if newValue >= 1.0, oldValue < 1.0 {
                triggerCompletionCelebration()
            }
        }

        if isCelebratingCompletion {
            ConfettiOverlay()
                .allowsHitTesting(false)
        }
        }
    }

    private func triggerCompletionCelebration() {
        isCelebratingCompletion = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isCelebratingCompletion = false
        }
    }
}

private struct ConfettiOverlay: View {
    @Environment(\.appColors) private var colors
    @State private var animate: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    let xOffset = CGFloat(index - 4) * 12

                    Image(systemName: index.isMultiple(of: 2) ? "sparkles" : "circle.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 14 : 6, weight: .medium))
                        .foregroundStyle(
                            index.isMultiple(of: 2) ? Color.yellow : colors.primary.opacity(0.95)
                        )
                        .offset(
                            x: animate ? xOffset : 0,
                            y: animate ? -geometry.size.height * 0.4 : 0
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0)
                                .delay(Double(index) * 0.03),
                            value: animate
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                animate = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()

        GoalCardView(
            goal: Goal(
                name: "Vacation",
                targetAmount: 2000,
                currentAmount: 750,
                dueDate: Calendar.current.date(byAdding: .month, value: 6, to: .now)
            )
        )
        .padding(24)
    }
}

