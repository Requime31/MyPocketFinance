import Foundation

enum GoalStatus: String, CaseIterable, Hashable, Codable {
    case active
    case nearlyAchieved
    case completed
}

enum GoalCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case savings
    case travel
    case emergency
    case education
    case lifestyle
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .savings:
            return "Savings"
        case .travel:
            return "Travel"
        case .emergency:
            return "Emergency"
        case .education:
            return "Education"
        case .lifestyle:
            return "Lifestyle"
        case .other:
            return "Other"
        }
    }
}

struct GoalContribution: Identifiable, Hashable, Codable {
    let id: UUID
    let amount: Decimal
    let date: Date
    let note: String?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
    }
}

struct Goal: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var dueDate: Date?
    var category: GoalCategory
    var currency: Transaction.Currency
    var contributions: [GoalContribution]
    var createdAt: Date

    /// 0...1 — доля достигнутого прогресса
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let ratio = (currentAmount as NSDecimalNumber).doubleValue / (targetAmount as NSDecimalNumber).doubleValue
        return min(max(ratio, 0), 1)
    }

    /// Статус цели на основе прогресса
    var status: GoalStatus {
        if progress >= 1 {
            return .completed
        } else if progress >= 0.75 {
            return .nearlyAchieved
        } else {
            return .active
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        dueDate: Date? = nil,
        category: GoalCategory = .other,
        currency: Transaction.Currency = .usd,
        contributions: [GoalContribution] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.dueDate = dueDate
        self.category = category
        self.currency = currency
        self.contributions = contributions
        self.createdAt = createdAt
    }
}

