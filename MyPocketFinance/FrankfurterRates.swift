import Foundation

struct FrankfurterRates: Codable {
    let date: String
    let base: String
    let quote: String
    let rate: Decimal
    
    enum FrankfurterRatesError: Error {
        case badURL
        case notHTTP
        case badStatus(Int)
        case empty
    }
    
    static func fetchUSDToEURRow() async throws -> FrankfurterRates {
        guard let url = URL(string: "https://api.frankfurter.dev/v2/rates?base=USD&quotes=EUR") else {
            throw FrankfurterRatesError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse else {
            throw FrankfurterRatesError.notHTTP
        }
        guard (200...299).contains(http.statusCode) else {
            throw FrankfurterRatesError.badStatus(http.statusCode)
        }
        
        let rows = try JSONDecoder().decode([FrankfurterRates].self, from: data)
        guard let first = rows.first else {
            throw FrankfurterRatesError.empty
        }

        ExchangeRateCache.save(from: first)
        return first
    }
}
