import Foundation

enum AnalyticsPeriod: Equatable {
    case week
    case month
    case year
}

struct PeriodSummary {
    struct Comparison {
        let percentageChange: Double
        let isIncrease: Bool
    }

    let totalIncome: Decimal
    let totalExpenses: Decimal
    let netBalance: Decimal
    let comparison: Comparison?
}

struct CashflowPoint: Identifiable, Equatable {
    let id = UUID()
    let periodLabel: String
    let income: Decimal
    let expenses: Decimal

    var incomeDouble: Double {
        NSDecimalNumber(decimal: income).doubleValue
    }

    var expensesDouble: Double {
        NSDecimalNumber(decimal: expenses).doubleValue
    }
}

struct TransactionAnalyticsService {


    func summarizePeriod(
        transactions: [Transaction],
        period: AnalyticsPeriod,
        displayCurrency: Transaction.Currency
    ) -> PeriodSummary {
        let calendar = Calendar.current
        let now = Date()

        let currentRange = makeDateRange(for: period, calendar: calendar, now: now)
        let current = filter(transactions: transactions, in: currentRange)

        let income = sum(
            transactions: current,
            type: .income,
            displayCurrency: displayCurrency
        )

        let expenses = sum(
            transactions: current,
            type: .expense,
            displayCurrency: displayCurrency
        )

        let net = income - expenses

        let comparison: PeriodSummary.Comparison?
        if let previousRange = makePreviousDateRange(for: period, relativeTo: currentRange, calendar: calendar) {
            let previous = filter(transactions: transactions, in: previousRange)
            let previousExpenses = sum(
                transactions: previous,
                type: .expense,
                displayCurrency: displayCurrency
            )

            let currentDouble = NSDecimalNumber(decimal: expenses).doubleValue
            let previousDouble = NSDecimalNumber(decimal: previousExpenses).doubleValue

            if previousDouble > 0, currentDouble > 0 {
                let changePercent = (currentDouble - previousDouble) / previousDouble * 100
                comparison = PeriodSummary.Comparison(
                    percentageChange: abs(changePercent),
                    isIncrease: changePercent >= 0
                )
            } else {
                comparison = nil
            }
        } else {
            comparison = nil
        }

        return PeriodSummary(
            totalIncome: income,
            totalExpenses: expenses,
            netBalance: net,
            comparison: comparison
        )
    }

    func categorySpending(
        transactions: [Transaction],
        period: AnalyticsPeriod,
        displayCurrency: Transaction.Currency
    ) -> [CategorySpending] {
        let range = makeDateRange(for: period, calendar: .current, now: Date())
        let filteredExpenses = filter(transactions: transactions, in: range).filter { $0.type == .expense }

        var totals: [Transaction.Category: Decimal] = [:]

        for transaction in filteredExpenses {
            let converted = transaction.currency.convert(amount: transaction.amount, to: displayCurrency)
            totals[transaction.category, default: 0] += converted
        }

        return totals
            .map { CategorySpending(category: $0.key, amount: $0.value) }
            .sorted { $0.amountDouble > $1.amountDouble }
    }

    func spendingTrend(
        transactions: [Transaction],
        period: AnalyticsPeriod,
        displayCurrency: Transaction.Currency
    ) -> [SpendingTrendPoint] {
        let range = makeDateRange(for: period, calendar: .current, now: Date())
        let filteredExpenses = filter(transactions: transactions, in: range).filter { $0.type == .expense }

        let calendar = Calendar.current

        switch period {
        case .week, .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"

            var dailyTotals: [Date: Decimal] = [:]

            for transaction in filteredExpenses {
                let day = calendar.startOfDay(for: transaction.date)
                let converted = transaction.currency.convert(amount: transaction.amount, to: displayCurrency)
                dailyTotals[day, default: 0] += converted
            }

            return dailyTotals
                .sorted { $0.key < $1.key }
                .map { date, total in
                    SpendingTrendPoint(
                        periodLabel: formatter.string(from: date),
                        amount: total
                    )
                }

        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"

            var monthlyTotals: [Int: Decimal] = [:]

            for transaction in filteredExpenses {
                let month = calendar.component(.month, from: transaction.date)
                let converted = transaction.currency.convert(amount: transaction.amount, to: displayCurrency)
                monthlyTotals[month, default: 0] += converted
            }

            let year = calendar.component(.year, from: Date())

            return monthlyTotals
                .sorted { $0.key < $1.key }
                .map { month, total in
                    let components = DateComponents(year: year, month: month, day: 1)
                    let date = calendar.date(from: components) ?? Date()
                    return SpendingTrendPoint(
                        periodLabel: formatter.string(from: date),
                        amount: total
                    )
                }
        }
    }

    func cashflowTrend(
        transactions: [Transaction],
        period: AnalyticsPeriod,
        displayCurrency: Transaction.Currency
    ) -> [CashflowPoint] {
        let range = makeDateRange(for: period, calendar: .current, now: Date())
        let filtered = filter(transactions: transactions, in: range)

        let calendar = Calendar.current

        switch period {
        case .week, .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"

            var dailyIncome: [Date: Decimal] = [:]
            var dailyExpenses: [Date: Decimal] = [:]

            for transaction in filtered {
                let day = calendar.startOfDay(for: transaction.date)
                let converted = transaction.currency.convert(amount: transaction.amount, to: displayCurrency)

                switch transaction.type {
                case .income:
                    dailyIncome[day, default: 0] += converted
                case .expense:
                    dailyExpenses[day, default: 0] += converted
                }
            }

            let allDays = Set(dailyIncome.keys).union(dailyExpenses.keys)

            return allDays
                .sorted()
                .map { date in
                    CashflowPoint(
                        periodLabel: formatter.string(from: date),
                        income: dailyIncome[date] ?? 0,
                        expenses: dailyExpenses[date] ?? 0
                    )
                }

        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"

            var monthlyIncome: [Int: Decimal] = [:]
            var monthlyExpenses: [Int: Decimal] = [:]

            for transaction in filtered {
                let month = calendar.component(.month, from: transaction.date)
                let converted = transaction.currency.convert(amount: transaction.amount, to: displayCurrency)

                switch transaction.type {
                case .income:
                    monthlyIncome[month, default: 0] += converted
                case .expense:
                    monthlyExpenses[month, default: 0] += converted
                }
            }

            let allMonths = Set(monthlyIncome.keys).union(monthlyExpenses.keys)
            let year = calendar.component(.year, from: Date())

            return allMonths
                .sorted()
                .map { month in
                    let components = DateComponents(year: year, month: month, day: 1)
                    let date = calendar.date(from: components) ?? Date()
                    return CashflowPoint(
                        periodLabel: formatter.string(from: date),
                        income: monthlyIncome[month] ?? 0,
                        expenses: monthlyExpenses[month] ?? 0
                    )
                }
        }
    }


    private func makeDateRange(
        for period: AnalyticsPeriod,
        calendar: Calendar,
        now: Date
    ) -> (start: Date, end: Date) {
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

    private func makePreviousDateRange(
        for period: AnalyticsPeriod,
        relativeTo currentRange: (start: Date, end: Date),
        calendar: Calendar
    ) -> (start: Date, end: Date)? {
        switch period {
        case .week:
            if let previousStart = calendar.date(byAdding: .day, value: -7, to: currentRange.start),
               let previousEnd = calendar.date(byAdding: .day, value: -1, to: currentRange.start) {
                return (previousStart, previousEnd)
            }
        case .month:
            if let previousMonthEnd = calendar.date(byAdding: .day, value: -1, to: currentRange.start),
               let interval = calendar.dateInterval(of: .month, for: previousMonthEnd) {
                return (interval.start, interval.end)
            }
        case .year:
            if let previousYearEnd = calendar.date(byAdding: .day, value: -1, to: currentRange.start),
               let interval = calendar.dateInterval(of: .year, for: previousYearEnd) {
                return (interval.start, interval.end)
            }
        }

        return nil
    }

    private func filter(
        transactions: [Transaction],
        in range: (start: Date, end: Date)
    ) -> [Transaction] {
        transactions.filter { transaction in
            transaction.date >= range.start && transaction.date < range.end
        }
    }

    private func sum(
        transactions: [Transaction],
        type: Transaction.Kind,
        displayCurrency: Transaction.Currency
    ) -> Decimal {
        transactions
            .filter { $0.type == type }
            .map { $0.currency.convert(amount: $0.amount, to: displayCurrency) }
            .reduce(0, +)
    }
}

