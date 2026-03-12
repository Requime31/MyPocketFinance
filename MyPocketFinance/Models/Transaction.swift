import Foundation

struct Transaction: Identifiable, Hashable, Codable {
    enum Currency: String, CaseIterable, Codable, Identifiable {
        case usd = "USD"
        case eur = "EUR"

        var id: String { rawValue }

        /// FX rates expressed as: 1 unit of this currency equals `rateToUSD` USD.
        ///
        /// We follow the example you gave:
        /// 1 USD = 0.8 EUR  ⇒  1 EUR = 1 / 0.8 = 1.25 USD
        fileprivate var rateToUSD: Decimal {
            switch self {
            case .usd: return 1
            case .eur: return Decimal(string: "1.25") ?? 1.25
            }
        }

        func convert(amount: Decimal, to target: Currency) -> Decimal {
            if self == target { return amount }

            // Convert from `self` to USD, then from USD to target.
            let amountInUSD = amount * rateToUSD

            let usdNumber = NSDecimalNumber(decimal: amountInUSD)
            let targetRate = NSDecimalNumber(decimal: target.rateToUSD)
            guard targetRate != 0 else { return amount }

            let converted = usdNumber.dividing(by: targetRate)
            return converted.decimalValue
        }
    }

    enum Category: String, CaseIterable, Codable, Identifiable {
        case income
        case housing
        case food
        case transportation
        case entertainment
        case savings
        case utilities
        case healthcare
        case other

        var id: String { rawValue }

        var displayName: String {
            rawValue.capitalized
        }
    }

    enum Kind: String, Codable {
        case income
        case expense
    }

    let id: UUID
    var date: Date
    var amount: Decimal
    var currency: Currency
    var category: Category
    var type: Kind
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amount: Decimal,
        currency: Currency = .usd,
        category: Category,
        type: Kind,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.currency = currency
        self.category = category
        self.type = type
        self.note = note
    }
}

