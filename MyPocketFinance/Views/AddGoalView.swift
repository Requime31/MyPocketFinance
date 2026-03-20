import SwiftUI

struct AddGoalView: View {
    var onSave: (_ name: String, _ targetAmount: Decimal, _ initialAmount: Decimal, _ dueDate: Date?, _ category: GoalCategory, _ currency: Transaction.Currency) -> Void

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
    @State private var currency: Transaction.Currency = {
        let service = UserDefaultsSettingsService()
        let code = service.load().currencyCode
        let currency = Transaction.Currency(rawValue: code) ?? .usd
        return currency
    }()

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        Decimal(string: targetAmountText) == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: spacing.l) {
                    heroCard
                    detailsCard
                    categoryCard
                    timelineCard
                }
                .padding(.horizontal, spacing.l)
                .padding(.top, spacing.l)
                .padding(.bottom, spacing.xl)
            }
            .background(colors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetAmount = Decimal(string: targetAmountText) ?? 0
        let initialAmount = Decimal(string: initialAmountText) ?? 0
        let date = hasDueDate ? dueDate : nil

        onSave(trimmedName, targetAmount, initialAmount, date, category, currency)
        dismiss()
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Create a new goal")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            Text("Visualize your savings and stay motivated with a clear target and timeline.")
                .font(typography.body)
                .foregroundStyle(colors.textSecondary)
        }
        .padding(spacing.m)
        .background(
            LinearGradient(
                colors: [
                    colors.card,
                    colors.card.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
        )
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Goal details")
                .font(typography.subtitle)
                .foregroundStyle(colors.textPrimary)

            VStack(alignment: .leading, spacing: spacing.m) {
                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text("Name")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    HStack {
                        Image(systemName: "text.cursor")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(colors.accent)

                        TextField("Vacation in Italy", text: $name)
                            .font(typography.body)
                    }
                    .padding(.horizontal, spacing.m)
                    .padding(.vertical, spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [colors.background, colors.card],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .stroke(colors.subtleBorder.opacity(0.9), lineWidth: 1)
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
                        .padding(.top, spacing.s)
                        .padding(.horizontal, spacing.xs)
                    }
                }

                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text("Target amount")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(colors.primary)

                        TextField("0.00", text: $targetAmountText)
                            .keyboardType(.decimalPad)
                            .font(typography.body)
                    }
                    .padding(.horizontal, spacing.m)
                    .padding(.vertical, spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [colors.background, colors.card],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .stroke(colors.subtleBorder.opacity(0.9), lineWidth: 1)
                    )

                    HStack(spacing: spacing.s) {
                        quickAmountChip(amount: 500)
                        quickAmountChip(amount: 1000)
                        quickAmountChip(amount: 2000)
                    }
                    .padding(.top, spacing.s)
                }

                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text("Starting amount")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    HStack {
                        Image(systemName: "arrow.down.left.circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(colors.secondary)

                        TextField("Optional", text: $initialAmountText)
                            .keyboardType(.decimalPad)
                            .font(typography.body)
                    }
                    .padding(.horizontal, spacing.m)
                    .padding(.vertical, spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [colors.background, colors.card],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .stroke(colors.subtleBorder.opacity(0.9), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text("Currency")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)

                    currencySegment
                }
            }
        }
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Category")
                .font(typography.subtitle)
                .foregroundStyle(colors.textPrimary)

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
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Timeline")
                .font(typography.subtitle)
                .foregroundStyle(colors.textPrimary)

            Toggle("Set target date", isOn: $hasDueDate.animation())

            if hasDueDate {
                DatePicker(
                    "Estimated completion",
                    selection: $dueDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        PrimaryButton(title: "Save goal", action: save)
            .opacity(isSaveDisabled ? 0.5 : 1)
            .disabled(isSaveDisabled)
            .padding(.horizontal, spacing.l)
            .padding(.top, spacing.m)
            .padding(.bottom, spacing.l)
            .background(
                Rectangle()
                    .fill(colors.background.opacity(0.98))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
            )
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

    private func quickAmountChip(amount: Int) -> some View {
        let amountDecimal = Decimal(amount)
        let text = amountDecimal.appCurrencyString(code: currency.rawValue)

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

    private var currencySegment: some View {
        let options: [Transaction.Currency] = [.usd, .eur]

        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                .fill(colors.background)

            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == currency

                    Button {
                        guard !isSelected else { return }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            currency = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(typography.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, spacing.s)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius.m - 2, style: .continuous)
                                    .fill(
                                        isSelected
                                        ? colors.accent
                                        : Color.clear
                                    )
                            )
                            .foregroundStyle(isSelected ? Color.white : colors.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
        }
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
}

#Preview {
    AddGoalView { _, _, _, _, _, _ in }
}

