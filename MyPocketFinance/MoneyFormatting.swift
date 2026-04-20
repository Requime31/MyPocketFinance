import Foundation

enum AmountFieldParsing {
    /// Parses a user-entered amount (comma or dot as decimal separator).
    static func decimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed.replacingOccurrences(of: ",", with: "."))
    }
}

enum AppCurrencyFormatter {
    private static func makeFormatter(currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        if currencyCode.uppercased() == "USD" {
            formatter.currencySymbol = "$"
        }

        return formatter
    }

    static func string(from amount: Decimal, currencyCode: String) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatter = makeFormatter(currencyCode: currencyCode)
        return formatter.string(from: number) ?? "\(amount)"
    }

    static func string(from amount: Double, currencyCode: String) -> String {
        let number = NSNumber(value: amount)
        let formatter = makeFormatter(currencyCode: currencyCode)
        return formatter.string(from: number) ?? "\(amount)"
    }
}

extension Decimal {
    func appCurrencyString(code: String) -> String {
        AppCurrencyFormatter.string(from: self, currencyCode: code)
    }
}

extension Double {
    func appCurrencyString(code: String) -> String {
        AppCurrencyFormatter.string(from: self, currencyCode: code)
    }
}

