import Foundation

enum ExchangeRateCache {
    private static let defaults = UserDefaults.standard
    private static let eurPerUsdKey = "exchangeRate.eurPerUsd"
    private static let dateKey = "exchangeRate.date"

    /// Used when no cached rate exists (first launch offline). Matches the previous hardcoded EUR→USD assumption.
    private static let fallbackUsdPerEur = Decimal(string: "1.25") ?? 1.25
    
    static func save(eurPerUsd: Decimal, dateString: String) {
        defaults.set(eurPerUsd.description, forKey: eurPerUsdKey)
        defaults.set(dateString, forKey: dateKey)
    }
    
    static func loadEurPerUsd() -> Decimal? {
        guard let s = defaults.string(forKey: eurPerUsdKey) else { return nil }
        return Decimal(string: s)
    }

    /// How many USD one EUR is worth. Frankfurter (and ``loadEurPerUsd()``) store EUR per 1 USD.
    static func usdPerEur() -> Decimal {
        guard let eurPerUsd = loadEurPerUsd(), eurPerUsd > 0 else {
            return fallbackUsdPerEur
        }
        let one = NSDecimalNumber(decimal: 1)
        let denom = NSDecimalNumber(decimal: eurPerUsd)
        return one.dividing(by: denom).decimalValue
    }
    
    static func save(from row: FrankfurterRates) {
        save(eurPerUsd: row.rate, dateString: row.date)
    }
    
    static func clear() {
        defaults.removeObject(forKey: eurPerUsdKey)
        defaults.removeObject(forKey: dateKey)
    }
}


