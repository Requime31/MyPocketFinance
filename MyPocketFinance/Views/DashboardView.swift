import SwiftUI

struct DashboardView: View {
    let onAddTransaction: () -> Void
    
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius
    
    @State private var animateChart = false
    @State private var selectedTransaction: Transaction?
    
    init(onAddTransaction: @escaping () -> Void = {}) {
        self.onAddTransaction = onAddTransaction
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: spacing.l) {
                    BalanceCardView(
                        totalBalance: viewModel.totalBalance,
                        income: viewModel.totalIncome,
                        expenses: viewModel.totalExpenses,
                        currencyCode: viewModel.displayCurrency.rawValue,
                        currency: viewModel.displayCurrency,
                        onCurrencyChange: viewModel.updateDisplayCurrency
                    )
                    .transition(.opacity.combined(with: .scale))
                    .animation(.spring(response: 0.7, dampingFraction: 0.85), value: viewModel.totalBalance)

                    if let comparison = viewModel.comparisonText {
                        Text(comparison)
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }

                    ExpenseChartSection(
                        slices: viewModel.expenseBreakdown,
                        totalExpenses: viewModel.totalExpenses,
                        currencyCode: viewModel.displayCurrency.rawValue,
                        selectedPeriod: viewModel.selectedPeriod,
                        onPeriodChange: viewModel.updatePeriod,
                        animate: animateChart
                    )

                    VStack(alignment: .leading, spacing: spacing.s) {
                        HStack {
                            Text("Recent Transactions")
                                .font(typography.subtitle)
                                .foregroundStyle(colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)

                            Spacer()
                        }

                        CategoryFilterChips(
                            selectedCategory: viewModel.selectedCategory,
                            onChange: viewModel.updateCategoryFilter
                        )

                        VStack(spacing: spacing.s) {
                            ForEach(viewModel.filteredTransactions.prefix(5)) { transaction in
                                Button {
                                    selectedTransaction = transaction
                                } label: {
                                    TransactionRowView(transaction: transaction)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(spacing.l)
                .padding(.bottom, 80)
            }
            .refreshable {
                viewModel.load()
            }
            .background(colors.background.ignoresSafeArea())
            
            FloatingAddButton(action: onAddTransaction)
                .padding(spacing.l)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                    animateChart = true
                }
            }
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionsDidChange)) { _ in
            viewModel.load()
            animateChart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                    animateChart = true
                }
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(
                transaction: transaction,
                onUpdate: { updated in
                    InMemoryTransactionService.shared.update(updated)
                    viewModel.load()
                },
                onDelete: { deleted in
                    InMemoryTransactionService.shared.delete(deleted)
                    viewModel.load()
                }
            )
        }
    }
}

// MARK: - Category Filter Chips

private struct CategoryFilterChips: View {
    let selectedCategory: Transaction.Category?
    let onChange: (Transaction.Category?) -> Void

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing

    // We exclude `.income` here to align with the expense categories grid.
    private let filterCategories: [Transaction.Category] = [
        .food, .transportation, .entertainment, .housing, .utilities, .savings, .healthcare, .other
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing.s) {
                categoryChip(
                    title: "All",
                    icon: "line.3.horizontal.decrease.circle",
                    isSelected: selectedCategory == nil
                ) {
                    onChange(nil)
                }

                ForEach(filterCategories, id: \.self) { category in
                    categoryChip(
                        title: category.displayName,
                        icon: iconName(for: category),
                        isSelected: selectedCategory == category
                    ) {
                        let newValue = (selectedCategory == category) ? nil : category
                        onChange(newValue)
                    }
                }
            }
            .padding(.vertical, spacing.xs)
        }
    }

    private func categoryChip(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text(title)
                    .font(typography.caption.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, spacing.s)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? colors.accent.opacity(0.18)
                        : colors.card
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? colors.accent : colors.subtleBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func iconName(for category: Transaction.Category) -> String {
        switch category {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .savings: return "banknote.fill"
        case .healthcare: return "cross.case.fill"
        case .other: return "ellipsis.circle.fill"
        case .income: return "arrow.down.left.circle.fill"
        }
    }
}

// MARK: - Expense Chart Section

private struct ExpenseChartSection: View {
    let slices: [DashboardViewModel.ExpenseCategorySlice]
    let totalExpenses: Decimal
    let currencyCode: String
    let selectedPeriod: DashboardViewModel.Period
    let onPeriodChange: (DashboardViewModel.Period) -> Void
    let animate: Bool
    
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            HStack {
                Text("Spending Breakdown")
                    .font(typography.subtitle)
                    .foregroundStyle(colors.textPrimary)

                Spacer()

                Picker("", selection: Binding(
                    get: { selectedPeriod },
                    set: { onPeriodChange($0) }
                )) {
                    ForEach(DashboardViewModel.Period.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
            
            VStack(spacing: spacing.l) {
                ZStack {
                    ExpenseDonutChart(slices: slices, animate: animate)
                        .frame(width: 160, height: 160)
                    
                    VStack(spacing: 4) {
                        Text(formattedAmount(totalExpenses))
                            .font(typography.subtitle)
                            .foregroundStyle(colors.textPrimary)
                        Text("This month")
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(spacing: spacing.s) {
                    ForEach(slices) { slice in
                        HStack(spacing: spacing.s) {
                            Capsule()
                                .fill(color(for: slice.category))
                                .frame(width: 18, height: 6)
                            
                            Text(slice.category.displayName)
                                .font(typography.body)
                                .foregroundStyle(colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(formattedAmount(slice.amount))
                                .font(typography.body)
                                .foregroundStyle(colors.textSecondary)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .frame(alignment: .trailing)
                        }
                    }
                    
                    if slices.isEmpty {
                        Text("No expenses recorded yet.")
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding(spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius.l,
                style: .continuous
            )
        )
        .shadow(color: colors.subtleBorder.opacity(0.8), radius: 18, x: 0, y: 10)
    }
    
    private func color(for category: Transaction.Category) -> Color {
        switch category {
        case .income:
            return colors.success
        case .housing:
            return colors.primary
        case .food:
            return colors.accent
        case .transportation:
            return Color.orange
        case .entertainment:
            return Color.purple
        case .savings:
            return Color.mint
        case .utilities:
            return Color.blue
        case .healthcare:
            return Color.red
        case .other:
            return colors.textSecondary
        }
    }

    private func formattedAmount(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = ""
        formatter.currencySymbol = currencyCode == "USD" ? "$" : "€"
        return formatter.string(from: number) ?? "\(value)"
    }
}

// MARK: - Donut Chart Shape

private struct ExpenseDonutChart: View {
    let slices: [DashboardViewModel.ExpenseCategorySlice]
    let animate: Bool
    
    @Environment(\.appColors) private var colors
    
    private struct SliceWithAngles: Identifiable {
        let id: UUID
        let category: Transaction.Category
        let startAngle: Angle
        let endAngle: Angle
    }
    
    private var slicesWithAngles: [SliceWithAngles] {
        guard !slices.isEmpty else { return [] }

        let anglePerSlice = 360.0 / Double(slices.count)
        var result: [SliceWithAngles] = []
        var currentStart = Angle(degrees: -90)

        for slice in slices {
            let end = currentStart + Angle(degrees: anglePerSlice * (animate ? 1 : 0))
            result.append(
                SliceWithAngles(
                    id: slice.id,
                    category: slice.category,
                    startAngle: currentStart,
                    endAngle: end
                )
            )
            currentStart = end
        }

        return result
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(slicesWithAngles.enumerated()), id: \.element.id) { index, element in
                DonutSliceShape(startAngle: element.startAngle, endAngle: element.endAngle)
                    .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .fill(color(for: element.category))
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.85)
                            .delay(Double(index) * 0.05),
                        value: animate
                    )
            }
        }
    }
    
    private func color(for category: Transaction.Category) -> Color {
        switch category {
        case .income:
            return colors.success
        case .housing:
            return colors.primary
        case .food:
            return colors.accent
        case .transportation:
            return Color.orange
        case .entertainment:
            return Color.purple
        case .savings:
            return Color.mint
        case .utilities:
            return Color.blue
        case .healthcare:
            return Color.red
        case .other:
            return colors.textSecondary
        }
    }
}

private struct DonutSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Floating Add Button

private struct FloatingAddButton: View {
    let action: () -> Void
    
    @Environment(\.appColors) private var colors
    @Environment(\.appSpacing) private var spacing
    @State private var isPressed = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colors.accentGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 60, height: 60)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .shadow(color: colors.accent.opacity(0.45), radius: 18, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .padding(.bottom, spacing.s)
    }
}

#Preview {
    DashboardView()
}

