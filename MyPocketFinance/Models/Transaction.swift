import Foundation

struct Transaction: Identifiable, Hashable, Codable {
    enum Currency: String, CaseIterable, Codable, Identifiable {
        case usd = "USD"
        case eur = "EUR"

        var id: String { rawValue }

        fileprivate var rateToUSD: Decimal {
            switch self {
            case .usd: return 1
            case .eur: return ExchangeRateCache.usdPerEur()
            }
        }

        func convert(amount: Decimal, to target: Currency) -> Decimal {
            if self == target { return amount }

            let amountInUSD = amount * rateToUSD

            let usdNumber = NSDecimalNumber(decimal: amountInUSD)
            let targetRate = NSDecimalNumber(decimal: target.rateToUSD)
            guard targetRate != 0 else { return amount }

            let converted = usdNumber.dividing(by: targetRate)
            return converted.decimalValue
        }

        /// Display / settings currency: only USD and EUR are supported in the app.
        static func appCurrency(fromCode code: String) -> Currency {
            switch code.uppercased() {
            case "EUR": return .eur
            default: return .usd
            }
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

