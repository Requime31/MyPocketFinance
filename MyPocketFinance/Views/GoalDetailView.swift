import SwiftUI

struct GoalDetailView: View {
    @ObservedObject var viewModel: GoalsViewModel
    let goalID: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var showQuickContribution: Bool = false
    @State private var progressBarFill: Double = 0
    @State private var quickAmountText: String = ""
    @State private var quickNoteText: String = ""
    @State private var quickError: String?
    @State private var highlightMotivation: Bool = false
    /// After delete the goal is gone from the model before the sheet closes; avoid flashing "Goal not found".
    @State private var isDeletingGoal: Bool = false

    private var goal: Goal? {
        viewModel.goal(withId: goalID)
    }

    var body: some View {
        Group {
            if let goal {
                ScrollView {
                    VStack(alignment: .leading, spacing: spacing.l) {
                        header(for: goal)
                        progressSection(for: goal)
                        planSection(for: goal)
                        contributionsSection(for: goal)
                        deleteSection(for: goal)
                    }
                    .padding(spacing.l)
                }
                .background(colors.background.ignoresSafeArea())
                .navigationTitle(goal.name)
                .navigationBarTitleDisplayMode(.inline)
            } else if isDeletingGoal {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(colors.background)
            } else {
                ContentUnavailableView(
                    "Goal not found",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }

    private func header(for goal: Goal) -> some View {
        HStack(alignment: .top, spacing: spacing.m) {
            ZStack {
                Circle()
                    .fill(colors.card)
                    .frame(width: 44, height: 44)
                    .shadow(color: colors.subtleBorder.opacity(0.6), radius: 8, x: 0, y: 4)

                Image(systemName: categoryIconName(for: goal.category))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(statusColor(for: goal.status))
            }

            VStack(alignment: .leading, spacing: spacing.xs) {
                Text("Goal overview")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: spacing.s) {
                    Text(goal.name)
                        .font(typography.title)
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: spacing.s)

                    Text(statusText(for: goal.status))
                        .font(typography.caption)
                        .padding(.horizontal, spacing.s)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(statusColor(for: goal.status).opacity(0.12))
                        )
                        .foregroundStyle(statusColor(for: goal.status))
                }

                Text(goal.category.title)
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
        }
        .padding(spacing.m)
        .background(
            LinearGradient(
                colors: [
                    colors.card,
                    colors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func progressSection(for goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Progress")
                .font(typography.subtitle)
                .foregroundStyle(colors.textPrimary)

            VStack(alignment: .leading, spacing: spacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Target")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    Spacer()

                    Text(goal.targetAmount.appCurrencyString(code: goal.currency.rawValue))
                        .font(typography.title.weight(.semibold))
                        .foregroundStyle(colors.textPrimary)
                        .monospacedDigit()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(colors.background.opacity(0.85))

                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: progressGradientColors(for: goal),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressBarFill)
                    }
                }
                .frame(height: 10)

                HStack(alignment: .firstTextBaseline) {
                    Text(goal.currentAmount.appCurrencyString(code: goal.currency.rawValue))
                        .font(typography.body.weight(.medium))
                        .foregroundStyle(colors.textPrimary)
                        .monospacedDigit()

                    Spacer()

                    Text(progressPercentLabel(for: goal))
                        .font(typography.caption.weight(.semibold))
                        .foregroundStyle(colors.textSecondary)
                        .monospacedDigit()
                }
            }
            .onAppear {
                progressBarFill = 0
                withAnimation(.spring(response: 0.65, dampingFraction: 0.88)) {
                    progressBarFill = goal.progress
                }
            }
            .onChange(of: goal.currentAmount) { _, _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    progressBarFill = goal.progress
                }
            }
            .onChange(of: goal.targetAmount) { _, _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    progressBarFill = goal.progress
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    highlightMotivation.toggle()
                }
            }

            VStack(alignment: .leading, spacing: spacing.s) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showQuickContribution.toggle()
                    }
                } label: {
                    HStack(spacing: spacing.s) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .semibold))

                        Text("Add contribution")
                            .font(typography.caption.weight(.medium))

                        Spacer()

                        Image(systemName: showQuickContribution ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, spacing.m)
                    .padding(.vertical, spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colors.accent.opacity(0.16))
                    )
                    .foregroundStyle(colors.accent)
                }
                .buttonStyle(.plain)

                if showQuickContribution {
                    VStack(alignment: .leading, spacing: spacing.s) {
                        HStack(spacing: spacing.s) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(colors.accent)

                            TextField("Amount", text: $quickAmountText)
                                .keyboardType(.numberPad)
                                .onChange(of: quickAmountText, initial: false) { _, newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        quickAmountText = filtered
                                    }
                                }
                                .font(typography.body)
                        }
                        .padding(.horizontal, spacing.m)
                        .padding(.vertical, spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colors.background)
                        )

                        HStack(spacing: spacing.s) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(colors.secondary)

                            TextField("Note (optional)", text: $quickNoteText)
                                .font(typography.body)
                        }
                        .padding(.horizontal, spacing.m)
                        .padding(.vertical, spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colors.background)
                        )

                        if let quickError {
                            Text(quickError)
                                .font(typography.caption)
                                .foregroundStyle(colors.warning)
                        }

                        HStack {
                            Spacer()
                            Button {
                                handleQuickContributionSave(for: goal)
                            } label: {
                                Text("Save")
                                    .font(typography.caption.weight(.semibold))
                                    .padding(.horizontal, spacing.l)
                                    .padding(.vertical, spacing.xs)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(colors.accent)
                                    )
                                    .foregroundStyle(colors.onAccent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
    }

    private func planSection(for goal: Goal) -> some View {
        guard
            let dueDate = goal.dueDate,
            goal.targetAmount > goal.currentAmount
        else {
            return AnyView(EmptyView())
        }

        let calendar = Calendar.current
        let now = Date()
        guard let days = calendar.dateComponents([.day], from: now, to: dueDate).day,
              days > 0
        else {
            return AnyView(EmptyView())
        }

        let remainingAmount = goal.targetAmount - goal.currentAmount
        let weeksDouble = max(Double(days) / 7.0, 1.0)

        let remainingNumber = NSDecimalNumber(decimal: remainingAmount)
        let weeklyNumber = remainingNumber.dividing(by: NSDecimalNumber(value: weeksDouble))
        let weeklyAmount = weeklyNumber.decimalValue

        return AnyView(
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Plan & schedule")
                .font(typography.subtitle)

            HStack(alignment: .firstTextBaseline, spacing: spacing.s) {
                Label(
                    dueDate.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "calendar"
                )
                .font(typography.body)
                .foregroundStyle(colors.textSecondary)

                Spacer()

                Text("Remaining \(remainingAmount.appCurrencyString(code: goal.currency.rawValue))")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }

            Text(
                "If you add \(weeklyAmount.appCurrencyString(code: goal.currency.rawValue)) per week, you'll reach this goal by \(dueDate.formatted(date: .abbreviated, time: .omitted))."
            )
            .font(typography.body)
            .foregroundStyle(colors.textSecondary)
        }
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(highlightMotivation ? colors.accent.opacity(0.12) : colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(highlightMotivation ? colors.accent : colors.subtleBorder, lineWidth: 1)
        )
        )
    }

    private func contributionsSection(for goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            HStack {
                Text("Contributions")
                    .font(typography.subtitle)
                Spacer()
            }

            if goal.contributions.isEmpty {
                Text("No contributions yet")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            } else {
                ForEach(Array(goal.contributions.sorted(by: { $0.date > $1.date }).enumerated()), id: \.element.id) { index, contribution in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(contribution.date.formatted(date: .abbreviated, time: .shortened))
                                .font(typography.caption)
                                .foregroundStyle(colors.textSecondary)

                            Spacer()

                            Text(contribution.amount.appCurrencyString(code: goal.currency.rawValue))
                                .font(typography.body)
                                .foregroundStyle(colors.textPrimary)
                        }

                        if let note = contribution.note, !note.isEmpty {
                            Text(note)
                                .font(typography.caption)
                                .foregroundStyle(colors.textSecondary)
                        }
                        if index < goal.contributions.count - 1 {
                            Divider()
                                .overlay(colors.subtleBorder)
                        }
                    }
                }
            }
        }
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
    }

    private func deleteSection(for goal: Goal) -> some View {
        Button(role: .destructive) {
            isDeletingGoal = true
            DispatchQueue.main.async {
                viewModel.delete(goal)
                withAnimation(.snappy(duration: 0.32, extraBounce: 0.04)) {
                    dismiss()
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Delete Goal")
                    .font(typography.body.weight(.semibold))
                Spacer()
            }
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(Color.red.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDeletingGoal)
        .padding(.top, spacing.l)
    }

    private func statusText(for status: GoalStatus) -> String {
        switch status {
        case .active:
            return "Active"
        case .nearlyAchieved:
            return "Nearly achieved"
        case .completed:
            return "Completed"
        }
    }

    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .active:
            return colors.textSecondary
        case .nearlyAchieved:
            return colors.primary
        case .completed:
            return .green
        }
    }
    
    private func handleQuickContributionSave(for goal: Goal) {
        let trimmed = quickAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            quickError = "Please enter an amount."
            return
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: normalized), amount > 0 else {
            quickError = "Invalid amount."
            return
        }

        quickError = nil
        viewModel.addContribution(to: goal, amount: amount, note: quickNoteText.isEmpty ? nil : quickNoteText)

        quickAmountText = ""
        quickNoteText = ""

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showQuickContribution = false
        }
    }

    private func progressGradientColors(for goal: Goal) -> [Color] {
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

    private func progressPercentLabel(for goal: Goal) -> String {
        guard goal.targetAmount > 0 else { return "0%" }
        let current = (goal.currentAmount as NSDecimalNumber).doubleValue
        let target = (goal.targetAmount as NSDecimalNumber).doubleValue
        let percent = (current / target) * 100
        return "\(Int(round(percent)))%"
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
}

