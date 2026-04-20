import SwiftUI

struct AddGoalView: View {
    var onSave: (_ name: String, _ targetAmount: Decimal, _ initialAmount: Decimal, _ dueDate: Date?, _ category: GoalCategory, _ currency: Transaction.Currency) -> Void

    init(
        initialCurrency: Transaction.Currency = .usd,
        onSave: @escaping (_ name: String, _ targetAmount: Decimal, _ initialAmount: Decimal, _ dueDate: Date?, _ category: GoalCategory, _ currency: Transaction.Currency) -> Void
    ) {
        self.onSave = onSave
        _selectedCurrency = State(initialValue: initialCurrency)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var name: String = ""
    @State private var targetAmountText: String = ""
    @State private var initialAmountText: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var category: GoalCategory = .other
    @State private var selectedCurrency: Transaction.Currency

    private var parsedTargetAmount: Decimal? {
        AmountFieldParsing.decimal(from: targetAmountText)
    }

    private var parsedInitialAmount: Decimal {
        AmountFieldParsing.decimal(from: initialAmountText) ?? 0
    }

    private var canSave: Bool {
        let nameOk = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard nameOk, let target = parsedTargetAmount, target > 0 else { return false }
        return parsedInitialAmount >= 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: spacing.l) {
                    nameSection
                    targetAmountSection
                    startingAmountSection
                    categorySection
                    timelineSection
                }
                .padding(.horizontal, spacing.l)
                .padding(.top, spacing.xl)
                .padding(.bottom, spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(colors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let targetAmount = parsedTargetAmount, targetAmount > 0 else { return }
        let initialAmount = max(0, parsedInitialAmount)
        let date = hasDueDate ? dueDate : nil

        onSave(trimmedName, targetAmount, initialAmount, date, category, selectedCurrency)
        dismiss()
    }

    // MARK: - Sections (aligned with AddTransactionView)

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Goal name")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            HStack(spacing: spacing.s) {
                ZStack {
                    Circle()
                        .fill(colors.accent.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: "target")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.accent)
                }

                TextField("e.g. Vacation in Italy", text: $name)
                    .font(typography.body)
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing.s) {
                    suggestionChip(title: "Emergency fund") {
                        name = "Emergency fund"
                        category = .emergency
                    }
                    suggestionChip(title: "Vacation") {
                        name = "Vacation"
                        category = .travel
                    }
                    suggestionChip(title: "New laptop") {
                        name = "New laptop"
                        category = .lifestyle
                    }
                }
                .padding(.vertical, spacing.xs)
            }
        }
    }

    private var targetAmountSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Target amount")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            HStack(spacing: spacing.s) {
                TextField("0.00", text: $targetAmountText)
                    .keyboardType(.decimalPad)
                    .font(typography.title)
                    .foregroundStyle(colors.textPrimary)
                    .onChange(of: targetAmountText, initial: false) { _, newValue in
                        let filtered = Self.sanitizeDecimalInput(newValue)
                        if filtered != newValue {
                            targetAmountText = filtered
                        }
                    }

                Spacer(minLength: spacing.s)

                HStack(spacing: 0) {
                    currencyChip(for: .usd)
                    currencyChip(for: .eur)
                }
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing.s) {
                    quickAmountChip(amount: 500)
                    quickAmountChip(amount: 1000)
                    quickAmountChip(amount: 2000)
                }
                .padding(.vertical, spacing.xs)
            }
        }
    }

    private var startingAmountSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Starting amount")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            HStack(spacing: spacing.s) {
                ZStack {
                    Circle()
                        .fill(colors.secondary.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: "arrow.down.left.circle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.secondary)
                }

                TextField("Optional", text: $initialAmountText)
                    .keyboardType(.decimalPad)
                    .font(typography.body)
                    .foregroundStyle(colors.textPrimary)
                    .onChange(of: initialAmountText, initial: false) { _, newValue in
                        let filtered = Self.sanitizeDecimalInput(newValue)
                        if filtered != newValue {
                            initialAmountText = filtered
                        }
                    }
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Category")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            CategorySelectorView(
                categories: GoalCategory.allCases,
                selectedCategory: Binding(
                    get: { category },
                    set: { category = $0 ?? .other }
                ),
                title: { $0.title },
                icon: { category in
                    (systemName: categoryIconName(for: category), color: categoryColor(for: category))
                }
            )
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Target date")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            VStack(alignment: .leading, spacing: spacing.m) {
                Toggle("Set target date", isOn: $hasDueDate.animation())

                if hasDueDate {
                    HStack(spacing: spacing.s) {
                        ZStack {
                            Circle()
                                .fill(colors.accent.opacity(0.18))
                                .frame(width: 28, height: 28)

                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(colors.accent)
                        }

                        DatePicker(
                            "Estimated completion",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(colors.subtleBorder.opacity(0.55))
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            PrimaryButton(title: "Save", action: save)
                .opacity(canSave ? 1 : 0.5)
                .disabled(!canSave)
                .padding(.horizontal, spacing.l)
                .padding(.top, spacing.m)
                .padding(.bottom, spacing.l)
        }
        .frame(maxWidth: .infinity)
        .background {
            colors.background
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: -6)
        }
    }

    private func suggestionChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary.opacity(0.9))
                .padding(.horizontal, spacing.s)
                .padding(.vertical, spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(colors.subtleBorder.opacity(0.02))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(colors.subtleBorder.opacity(0.25), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }

    private func currencyChip(for value: Transaction.Currency) -> some View {
        let isSelected = selectedCurrency == value

        return Button {
            guard !isSelected else { return }
            selectedCurrency = value
        } label: {
            Text(value.rawValue)
                .font(typography.caption.weight(.medium))
                .frame(width: 52)
                .padding(.vertical, spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius.s, style: .continuous)
                        .fill(isSelected ? colors.accent : colors.controlInactiveFill)
                )
                .foregroundStyle(isSelected ? colors.onAccent : colors.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private func quickAmountChip(amount: Int) -> some View {
        let amountDecimal = Decimal(amount)
        let text = amountDecimal.appCurrencyString(code: selectedCurrency.rawValue)

        return Button {
            targetAmountText = "\(amount)"
        } label: {
            Text(text)
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary.opacity(0.9))
                .padding(.horizontal, spacing.s)
                .padding(.vertical, spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(colors.subtleBorder.opacity(0.02))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(colors.subtleBorder.opacity(0.25), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
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

    private func categoryColor(for category: GoalCategory) -> Color {
        switch category {
        case .savings: return colors.success
        case .travel: return colors.primary
        case .emergency: return colors.warning
        case .education: return colors.secondary
        case .lifestyle: return colors.accent
        case .other: return colors.textSecondary
        }
    }

    private static func sanitizeDecimalInput(_ raw: String) -> String {
        let allowed = "0123456789.,"
        var filtered = raw.filter { allowed.contains($0) }

        let separators: [Character] = [".", ","]
        for separator in separators {
            let parts = filtered.split(separator: separator, omittingEmptySubsequences: false)
            if parts.count > 2 {
                filtered = parts.prefix(2).joined(separator: String(separator))
            }
        }

        return filtered
    }
}

#Preview {
    AddGoalView(initialCurrency: .usd) { _, _, _, _, _, _ in }
}
