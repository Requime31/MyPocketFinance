import Foundation
import Combine

enum ReportsTimeFilter: String, CaseIterable, Identifiable, Equatable {
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var analyticsPeriod: AnalyticsPeriod {
        switch self {
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }
}

struct CategorySpending: Identifiable, Equatable {
    let id = UUID()
    let category: Transaction.Category
    let amount: Decimal

    var amountDouble: Double {
        NSDecimalNumber(decimal: amount).doubleValue
    }
}

struct SpendingTrendPoint: Identifiable, Equatable {
    let id = UUID()
    let periodLabel: String
    let amount: Decimal

    var amountDouble: Double {
        NSDecimalNumber(decimal: amount).doubleValue
    }
}

struct GoalsOverviewStatistics {
    let totalTargetAmount: Decimal
    let totalCurrentAmount: Decimal
    let averageProgress: Double
    let statusCounts: [GoalStatus: Int]
    let categoryTotals: [GoalCategory: (current: Decimal, target: Decimal)]
}

struct StatisticInsight: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImageName: String
}

final class ReportsViewModel: ObservableObject {

    @Published private(set) var summary: PeriodSummary?
    @Published private(set) var categorySpending: [CategorySpending] = []
    @Published private(set) var spendingTrend: [SpendingTrendPoint] = []
    @Published private(set) var cashflowTrend: [CashflowPoint] = []
    @Published private(set) var goalsStatistics: GoalsOverviewStatistics?
    @Published private(set) var savingsRate: Double?
    @Published private(set) var contributionsThisPeriod: Decimal = 0
    @Published private(set) var insights: [StatisticInsight] = []

    @Published private(set) var displayCurrencyCode: String = "USD"

    @Published var selectedFilter: ReportsTimeFilter = .month {
        didSet { recalculate() }
    }


    private let transactionService: TransactionService
    private let goalService: GoalService
    private let settingsService: UserSettingsService
    private let analyticsService: TransactionAnalyticsService


    private var allTransactions: [Transaction] = []
    private var allGoals: [Goal] = []
    private var displayCurrency: Transaction.Currency = .usd


    init(
        transactionService: TransactionService = InMemoryTransactionService.shared,
        goalService: GoalService = UserDefaultsGoalService(),
        settingsService: UserSettingsService = UserDefaultsSettingsService(),
        analyticsService: TransactionAnalyticsService = TransactionAnalyticsService()
    ) {
        self.transactionService = transactionService
        self.goalService = goalService
        self.settingsService = settingsService
        self.analyticsService = analyticsService

        load()
    }


    func load() {
        let settings = settingsService.load()
        displayCurrency = Transaction.Currency.appCurrency(fromCode: settings.currencyCode)
        displayCurrencyCode = displayCurrency.rawValue.uppercased()

        allTransactions = transactionService.fetchTransactions()
        allGoals = goalService.fetchGoals()

        recalculate()
    }


    private func recalculate() {
        let period = selectedFilter.analyticsPeriod

        summary = analyticsService.summarizePeriod(
            transactions: allTransactions,
            period: period,
            displayCurrency: displayCurrency
        )

        categorySpending = analyticsService.categorySpending(
            transactions: allTransactions,
            period: period,
            displayCurrency: displayCurrency
        )

        spendingTrend = analyticsService.spendingTrend(
            transactions: allTransactions,
            period: period,
            displayCurrency: displayCurrency
        )

        cashflowTrend = analyticsService.cashflowTrend(
            transactions: allTransactions,
            period: period,
            displayCurrency: displayCurrency
        )

        goalsStatistics = calculateGoalsStatistics(
            goals: allGoals,
            displayCurrency: displayCurrency
        )

        savingsRate = calculateSavingsRate(summary: summary)
        contributionsThisPeriod = calculateContributionsThisPeriod(
            goals: allGoals,
            period: period,
            displayCurrency: displayCurrency
        )
        insights = buildInsights()
    }


    private func calculateGoalsStatistics(
        goals: [Goal],
        displayCurrency: Transaction.Currency
    ) -> GoalsOverviewStatistics? {
        guard !goals.isEmpty else { return nil }

        var totalTarget: Decimal = 0
        var totalCurrent: Decimal = 0
        var statusCounts: [GoalStatus: Int] = [:]
        var categoryTotals: [GoalCategory: (current: Decimal, target: Decimal)] = [:]

        for goal in goals {
            let convertedTarget = goal.currency.convert(amount: goal.targetAmount, to: displayCurrency)
            let convertedCurrent = goal.currency.convert(amount: goal.currentAmount, to: displayCurrency)

            totalTarget += convertedTarget
            totalCurrent += convertedCurrent

            statusCounts[goal.status, default: 0] += 1

            var entry = categoryTotals[goal.category] ?? (current: 0, target: 0)
            entry.current += convertedCurrent
            entry.target += convertedTarget
            categoryTotals[goal.category] = entry
        }

        let progresses = goals.map { $0.progress }
        let averageProgress = progresses.isEmpty ? 0 : progresses.reduce(0, +) / Double(progresses.count)

        return GoalsOverviewStatistics(
            totalTargetAmount: totalTarget,
            totalCurrentAmount: totalCurrent,
            averageProgress: averageProgress,
            statusCounts: statusCounts,
            categoryTotals: categoryTotals
        )
    }

    private func calculateSavingsRate(summary: PeriodSummary?) -> Double? {
        guard let summary else { return nil }
        let incomeDouble = NSDecimalNumber(decimal: summary.totalIncome).doubleValue
        let netDouble = NSDecimalNumber(decimal: summary.netBalance).doubleValue
        guard incomeDouble > 0 else { return nil }

        let fraction = netDouble / incomeDouble
        if fraction.isNaN || fraction.isInfinite {
            return nil
        }
        return max(0, min(1, fraction))
    }

    private func calculateContributionsThisPeriod(
        goals: [Goal],
        period: AnalyticsPeriod,
        displayCurrency: Transaction.Currency
    ) -> Decimal {
        guard !goals.isEmpty else { return 0 }

        let range = dateRange(for: period)
        var total: Decimal = 0

        for goal in goals {
            for contribution in goal.contributions where contribution.date >= range.start && contribution.date < range.end {
                let converted = goal.currency.convert(amount: contribution.amount, to: displayCurrency)
                total += converted
            }
        }

        return total
    }

    private func buildInsights() -> [StatisticInsight] {
        var result: [StatisticInsight] = []

        if let summary {
            let income = NSDecimalNumber(decimal: summary.totalIncome).doubleValue
            let expenses = NSDecimalNumber(decimal: summary.totalExpenses).doubleValue

            if income > 0 || expenses > 0 {
                let code = Transaction.Currency.appCurrency(fromCode: settingsService.load().currencyCode).rawValue
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = code

                let incomeText = formatter.string(from: NSNumber(value: income)) ?? "\(income)"
                let expensesText = formatter.string(from: NSNumber(value: expenses)) ?? "\(expenses)"

                result.append(
                    StatisticInsight(
                        title: "Income vs expenses",
                        subtitle: "\(incomeText) income • \(expensesText) spent",
                        systemImageName: "arrow.up.arrow.down"
                    )
                )
            }

            if let comparison = summary.comparison {
                let direction = comparison.isIncrease ? "higher" : "lower"
                let value = Int(comparison.percentageChange)
                result.append(
                    StatisticInsight(
                        title: "Change vs previous period",
                        subtitle: "Spending is \(value)% \(direction) than before",
                        systemImageName: "chart.line.uptrend.xyaxis"
                    )
                )
            }
        }

        if !categorySpending.isEmpty, let top = categorySpending.first {
            let amount = NSDecimalNumber(decimal: top.amount).doubleValue
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Transaction.Currency.appCurrency(fromCode: settingsService.load().currencyCode).rawValue
            let amountText = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"

            result.append(
                StatisticInsight(
                    title: "Top spending category",
                    subtitle: "\(top.category.displayName) • \(amountText)",
                    systemImageName: "chart.pie.fill"
                )
            )
        }

        return Array(result.prefix(3))
    }

    private func dateRange(for period: AnalyticsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .week:
            if let startOfDay = calendar.dateInterval(of: .day, for: now)?.start,
               let start = calendar.date(byAdding: .day, value: -6, to: startOfDay),
               let end = calendar.date(byAdding: .day, value: 1, to: startOfDay) {
                return (start, end)
            }
        case .month:
            if let interval = calendar.dateInterval(of: .month, for: now) {
                return (interval.start, interval.end)
            }
        case .year:
            if let interval = calendar.dateInterval(of: .year, for: now) {
                return (interval.start, interval.end)
            }
        }

        let startOfDay = calendar.startOfDay(for: now)
        return (startOfDay, now)
    }
}
