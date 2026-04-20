import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.appTypography) private var typography
    @Environment(\.appColors) private var colors
    @Environment(\.appSpacing) private var spacing

    @State private var isPresentingAddGoal = false
    @State private var selectedGoalForDetail: Goal?
    @State private var goalForQuickContribution: Goal?
    @State private var goalForEdit: Goal?
    @State private var goalToDelete: Goal?

    var body: some View {
        ScrollView {
            VStack(spacing: spacing.l) {
                header

                controls

                if viewModel.displayedGoals.isEmpty {
                    EmptyStateView(
                        iconName: "target",
                        title: "Set your first goal",
                        message: "Create savings goals for things that matter to you and track your progress over time.",
                        primaryActionTitle: "Add new goal",
                        primaryAction: { isPresentingAddGoal = true }
                    )
                    .padding(.top, spacing.m)
                } else {
                    LazyVStack(spacing: spacing.m) {
                        ForEach(Array(viewModel.displayedGoals.enumerated()), id: \.element.id) { index, goal in
                            Button {
                                selectedGoalForDetail = goal
                            } label: {
                                GoalCardView(goal: goal, animationDelay: Double(index) * 0.05)
                            }
                            .buttonStyle(.plain)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .offset(y: 10)),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                )
                            )
                            .swipeActions(edge: .trailing) {
                                Button {
                                    goalForQuickContribution = goal
                                } label: {
                                    Label("Add", systemImage: "plus.circle")
                                }
                                .tint(colors.primary)

                                Button {
                                    goalForEdit = goal
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    goalToDelete = goal
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, spacing.l)
            .padding(.vertical, spacing.l)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .background(colors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAddGoal = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
                .tint(colors.primary)
            }
        }
        .sheet(isPresented: $isPresentingAddGoal) {
            AddGoalView(
                initialCurrency: Transaction.Currency.appCurrency(fromCode: settingsViewModel.settings.currencyCode)
            ) { name, targetAmount, initialAmount, dueDate, category, currency in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.addGoal(
                        name: name,
                        targetAmount: targetAmount,
                        initialAmount: initialAmount,
                        dueDate: dueDate,
                        category: category,
                        currency: currency
                    )
                    viewModel.statusFilter = .all
                    viewModel.categoryFilter = .all
                    viewModel.searchText = ""
                }
                isPresentingAddGoal = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedGoalForDetail) { goal in
            NavigationStack {
                GoalDetailView(
                    viewModel: viewModel,
                    goalID: goal.id
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $goalForQuickContribution) { goal in
            AddContributionView(
                goal: goal
            ) { amount, note in
                viewModel.addContribution(to: goal, amount: amount, note: note)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $goalForEdit) { goal in
            EditGoalView(
                goal: goal
            ) { updatedName, updatedTarget, updatedDueDate, updatedCategory in
                viewModel.update(
                    goal,
                    name: updatedName,
                    targetAmount: updatedTarget,
                    dueDate: updatedDueDate,
                    category: updatedCategory
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Are you sure you want to delete this goal?",
            isPresented: Binding(
                get: { goalToDelete != nil },
                set: { newValue in
                    if !newValue {
                        goalToDelete = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let goalToDelete {
                Button("Delete goal", role: .destructive) {
                    viewModel.delete(goalToDelete)
                    self.goalToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                goalToDelete = nil
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search goals")
    }

    private var header: some View {
        let currencyCode = Transaction.Currency.appCurrency(fromCode: settingsViewModel.settings.currencyCode).rawValue

        return VStack(alignment: .leading, spacing: spacing.s) {
            Text("Savings goals")
                .font(typography.largeTitle)
                .foregroundStyle(colors.textPrimary)

            Text("Plan and track savings for the things that matter most.")
                .font(typography.body)
                .foregroundStyle(colors.textSecondary)

            HStack(spacing: spacing.m) {
                summaryCard(
                    title: "Saved so far",
                    amount: viewModel.totalCurrentAmount,
                    currencyCode: currencyCode
                )

                summaryCard(
                    title: "Total targets",
                    amount: viewModel.totalTargetAmount,
                    currencyCode: currencyCode
                )
            }
        }
    }

    private var controls: some View {
        VStack(spacing: spacing.s) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing.s) {
                    ForEach(GoalStatusFilter.allCases) { filter in
                        statusChip(for: filter)
                    }
                }
                .padding(.vertical, spacing.xs)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing.s) {
                    ForEach(GoalCategoryFilter.allCases) { filter in
                        categoryChip(for: filter)
                    }
                }
                .padding(.vertical, spacing.xs)
            }

            HStack {
                Text("Sort by")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)

                Spacer()

                Picker("Sort by", selection: $viewModel.sortOption) {
                    ForEach(GoalSortOption.allCases) { option in
                        Text(option.title)
                            .tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private func summaryCard(
        title: String,
        amount: Decimal,
        currencyCode: String
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            Text(title)
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            Text(amount.appCurrencyString(code: currencyCode))
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)
        }
        .padding(spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: colors.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.subtleBorder, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func statusChip(for filter: GoalStatusFilter) -> some View {
        let isSelected = viewModel.statusFilter == filter

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                viewModel.statusFilter = filter
            }
        } label: {
            Text(filter.title)
                .font(typography.caption)
                .padding(.horizontal, spacing.m)
                .padding(.vertical, spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                            ? colors.primary.opacity(0.16)
                            : colors.card
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            isSelected ? colors.primary : colors.subtleBorder,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .foregroundStyle(isSelected ? colors.primary : colors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private func categoryChip(for filter: GoalCategoryFilter) -> some View {
        let isSelected = viewModel.categoryFilter == filter

        let (label, color): (String, Color) = {
            switch filter {
            case .all:
                return ("All types", colors.textSecondary)
            case .savings:
                return (GoalCategory.savings.title, colors.success)
            case .travel:
                return (GoalCategory.travel.title, colors.primary)
            case .emergency:
                return (GoalCategory.emergency.title, colors.warning)
            case .education:
                return (GoalCategory.education.title, colors.secondary)
            case .lifestyle:
                return (GoalCategory.lifestyle.title, colors.accent)
            case .other:
                return (GoalCategory.other.title, colors.textSecondary)
            }
        }()

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                viewModel.categoryFilter = filter
            }
        } label: {
            HStack(spacing: spacing.xs) {
                Circle()
                    .fill(color.opacity(0.9))
                    .frame(width: 6, height: 6)

                Text(label)
                    .font(typography.caption)
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                        ? color.opacity(0.14)
                        : colors.card
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? color : colors.subtleBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .foregroundStyle(isSelected ? color : colors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalsView()
        .environmentObject(SettingsViewModel())
}

