import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var filteredTransactions: [Transaction] = []
    @Published private(set) var expenseBreakdown: [ExpenseCategorySlice] = []
    @Published private(set) var totalBalance: Decimal = 0
    @Published private(set) var totalIncome: Decimal = 0
    @Published private(set) var totalExpenses: Decimal = 0
    @Published private(set) var displayCurrency: Transaction.Currency = .usd
    @Published private(set) var comparisonText: String?
    @Published private(set) var selectedCategory: Transaction.Category?

    enum Period: String, CaseIterable, Identifiable {
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
    }

    @Published private(set) var selectedPeriod: Period = .month

    private let transactionService: TransactionService

    init(transactionService: TransactionService = InMemoryTransactionService.shared) {
        self.transactionService = transactionService
        load()
    }

    struct ExpenseCategorySlice: Identifiable {
        let id = UUID()
        let category: Transaction.Category
        let amount: Decimal
        let ratio: Double
    }

    func load() {
        transactions = transactionService.fetchTransactions()
        recalculate()
    }

    func updatePeriod(_ period: Period) {
        selectedPeriod = period
        recalculate()
    }

    func updateDisplayCurrency(_ currency: Transaction.Currency) {
        displayCurrency = currency
        recalculate()
    }

    func updateCategoryFilter(_ category: Transaction.Category?) {
        selectedCategory = category
        recalculate()
    }

    private func recalculate() {
        let items = transactions

        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedPeriod {
        case .week:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            startDate = weekStart ?? calendar.startOfDay(for: now)
        case .month:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start
            startDate = monthStart ?? calendar.startOfDay(for: now)
        case .year:
            let yearStart = calendar.dateInterval(of: .year, for: now)?.start
            startDate = yearStart ?? calendar.startOfDay(for: now)
        }

        // For recent transactions we keep a most-recent-first list, optionally filtered by category.
        let recentSource: [Transaction]
        if let category = selectedCategory {
            recentSource = items.filter { $0.category == category }
        } else {
            recentSource = items
        }
        filteredTransactions = recentSource.sorted { $0.date > $1.date }

        let filtered = items.filter { $0.date >= startDate && $0.date <= now }

        func convertedAmount(for transaction: Transaction) -> Decimal {
            transaction.currency.convert(amount: transaction.amount, to: displayCurrency)
        }

        let income = filtered
            .filter { $0.type == .income }
            .map { convertedAmount(for: $0) }
            .reduce(0, +)

        let expenses = filtered
            .filter { $0.type == .expense }
            .map { convertedAmount(for: $0) }
            .reduce(0, +)

        let totalExpenseDouble = NSDecimalNumber(decimal: expenses).doubleValue
        if totalExpenseDouble > 0 {
            let grouped = Dictionary(grouping: filtered.filter { $0.type == .expense }) { $0.category }
            expenseBreakdown = grouped.compactMap { category, transactions in
                let categoryAmount = transactions
                    .map { convertedAmount(for: $0) }
                    .reduce(0, +)

                let amountDouble = NSDecimalNumber(decimal: categoryAmount).doubleValue
                guard amountDouble > 0 else { return nil }

                return ExpenseCategorySlice(
                    category: category,
                    amount: categoryAmount,
                    ratio: amountDouble / totalExpenseDouble
                )
            }
            .sorted { $0.amount > $1.amount }
        } else {
            expenseBreakdown = []
        }

        totalIncome = income
        totalExpenses = expenses
        totalBalance = income - expenses

        updateComparison(
            allTransactions: items,
            currentExpenses: expenses,
            calendar: calendar,
            now: now
        )
    }

    private func updateComparison(
        allTransactions: [Transaction],
        currentExpenses: Decimal,
        calendar: Calendar,
        now: Date
    ) {
        // Only show comparison for monthly view.
        guard selectedPeriod == .month else {
            comparisonText = nil
            return
        }

        guard let currentMonthInterval = calendar.dateInterval(of: .month, for: now),
              let previousMonthEnd = calendar.date(byAdding: .day, value: -1, to: currentMonthInterval.start),
              let previousMonthInterval = calendar.dateInterval(of: .month, for: previousMonthEnd) else {
            comparisonText = nil
            return
        }

        func convertedAmount(for transaction: Transaction) -> Decimal {
            transaction.currency.convert(amount: transaction.amount, to: displayCurrency)
        }

        let previousExpenses = allTransactions
            .filter {
                $0.type == .expense &&
                $0.date >= previousMonthInterval.start &&
                $0.date < previousMonthInterval.end
            }
            .map { convertedAmount(for: $0) }
            .reduce(0, +)

        let current = NSDecimalNumber(decimal: currentExpenses).doubleValue
        let previous = NSDecimalNumber(decimal: previousExpenses).doubleValue

        guard previous > 0, current > 0 else {
            comparisonText = nil
            return
        }

        let changePercent = (current - previous) / previous * 100

        if changePercent < 0 {
            comparisonText = String(
                format: "Spending is %.0f%% lower than last month", abs(changePercent)
            )
        } else {
            comparisonText = String(
                format: "Spending is %.0f%% higher than last month", changePercent
            )
        }
    }
}

