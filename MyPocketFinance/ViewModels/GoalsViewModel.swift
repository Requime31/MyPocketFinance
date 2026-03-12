import Foundation
import Combine

final class GoalsViewModel: ObservableObject {
    @Published private(set) var goals: [Goal] = []
    @Published var statusFilter: GoalStatusFilter = .all
    @Published var sortOption: GoalSortOption = .byProgress
    @Published var categoryFilter: GoalCategoryFilter = .all
    @Published var searchText: String = ""

    private let goalService: PersistentGoalService

    init(goalService: PersistentGoalService = UserDefaultsGoalService()) {
        self.goalService = goalService
        load()
    }

    var displayedGoals: [Goal] {
        var result = goals
        result = filteredGoals(from: result, using: statusFilter)
        result = filteredGoals(from: result, using: categoryFilter)
        result = filteredGoals(from: result, searchText: searchText)
        return sortGoals(result, by: sortOption)
    }

    // Aggregate stats
    var totalTargetAmount: Decimal {
        goals.reduce(0) { $0 + $1.targetAmount }
    }

    var totalCurrentAmount: Decimal {
        goals.reduce(0) { $0 + $1.currentAmount }
    }

    func load() {
        goals = goalService.fetchGoals()
    }

    @MainActor
    func refresh() async {
        await MainActor.run {
            objectWillChange.send()
        }
    }

    func addGoal(
        name: String,
        targetAmount: Decimal,
        initialAmount: Decimal,
        dueDate: Date?,
        category: GoalCategory,
        currency: Transaction.Currency
    ) {
        let goal = Goal(
            name: name,
            targetAmount: targetAmount,
            currentAmount: initialAmount,
            dueDate: dueDate,
            category: category,
            currency: currency
        )

        goals.append(goal)
        goalService.saveGoals(goals)
        NotificationCenter.default.post(name: .goalsDidChange, object: nil)
    }

    func delete(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        goalService.saveGoals(goals)
        NotificationCenter.default.post(name: .goalsDidChange, object: nil)
    }

    func update(
        _ goal: Goal,
        name: String,
        targetAmount: Decimal,
        dueDate: Date?,
        category: GoalCategory
    ) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index].name = name
        goals[index].targetAmount = targetAmount
        goals[index].dueDate = dueDate
        goals[index].category = category
        goalService.saveGoals(goals)
        NotificationCenter.default.post(name: .goalsDidChange, object: nil)
    }

    func addContribution(
        to goal: Goal,
        amount: Decimal,
        note: String?
    ) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        guard amount > 0 else { return }

        var updatedGoal = goals[index]
        updatedGoal.currentAmount += amount
        let contribution = GoalContribution(amount: amount, note: note)
        updatedGoal.contributions.append(contribution)

        goals[index] = updatedGoal
        goalService.saveGoals(goals)
        NotificationCenter.default.post(name: .goalsDidChange, object: nil)
    }

    func goal(withId id: UUID) -> Goal? {
        goals.first { $0.id == id }
    }
}

// MARK: - Filtering & Sorting

enum GoalStatusFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case nearlyAchieved
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .active:
            return "Active"
        case .nearlyAchieved:
            return "Nearly"
        case .completed:
            return "Completed"
        }
    }
}

enum GoalCategoryFilter: String, CaseIterable, Identifiable {
    case all
    case savings
    case travel
    case emergency
    case education
    case lifestyle
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .savings:
            return GoalCategory.savings.title
        case .travel:
            return GoalCategory.travel.title
        case .emergency:
            return GoalCategory.emergency.title
        case .education:
            return GoalCategory.education.title
        case .lifestyle:
            return GoalCategory.lifestyle.title
        case .other:
            return GoalCategory.other.title
        }
    }

    func matches(_ category: GoalCategory) -> Bool {
        switch self {
        case .all:
            return true
        case .savings:
            return category == .savings
        case .travel:
            return category == .travel
        case .emergency:
            return category == .emergency
        case .education:
            return category == .education
        case .lifestyle:
            return category == .lifestyle
        case .other:
            return category == .other
        }
    }
}

enum GoalSortOption: String, CaseIterable, Identifiable {
    case byDeadline
    case byProgress
    case byTargetAmount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .byDeadline:
            return "Deadline"
        case .byProgress:
            return "Progress"
        case .byTargetAmount:
            return "Amount"
        }
    }
}

private extension GoalsViewModel {
    func filteredGoals(from goals: [Goal], using filter: GoalStatusFilter) -> [Goal] {
        switch filter {
        case .all:
            return goals
        case .active:
            return goals.filter { $0.status == .active }
        case .nearlyAchieved:
            return goals.filter { $0.status == .nearlyAchieved }
        case .completed:
            return goals.filter { $0.status == .completed }
        }
    }

    func filteredGoals(from goals: [Goal], using filter: GoalCategoryFilter) -> [Goal] {
        switch filter {
        case .all:
            return goals
        default:
            return goals.filter { filter.matches($0.category) }
        }
    }

    func filteredGoals(from goals: [Goal], searchText: String) -> [Goal] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return goals }

        return goals.filter { goal in
            goal.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func sortGoals(_ goals: [Goal], by option: GoalSortOption) -> [Goal] {
        switch option {
        case .byDeadline:
            return goals.sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (l?, r?):
                    return l < r
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.name < rhs.name
                }
            }
        case .byProgress:
            return goals.sorted { $0.progress > $1.progress }
        case .byTargetAmount:
            return goals.sorted { $0.targetAmount > $1.targetAmount }
        }
    }
}


