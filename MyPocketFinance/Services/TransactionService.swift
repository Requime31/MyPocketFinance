import Foundation

protocol TransactionService {
    func fetchTransactions() -> [Transaction]
    func add(_ transaction: Transaction)
    func update(_ transaction: Transaction)
    func delete(_ transaction: Transaction)
}

final class InMemoryTransactionService: TransactionService {
    static let shared = InMemoryTransactionService()

    private let storageKey = "transactions_storage_key"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storage = Self.loadFromDefaults(defaults: defaults, key: storageKey)
    }

    private var storage: [Transaction] = []

    func fetchTransactions() -> [Transaction] {
        storage.sorted { $0.date > $1.date }
    }

    func add(_ transaction: Transaction) {
        storage.append(transaction)
        persist()
        notifyChange()
    }

    func update(_ transaction: Transaction) {
        guard let index = storage.firstIndex(where: { $0.id == transaction.id }) else {
            return
        }
        storage[index] = transaction
        persist()
        notifyChange()
    }

    func delete(_ transaction: Transaction) {
        storage.removeAll { $0.id == transaction.id }
        persist()
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(storage)
            defaults.set(data, forKey: storageKey)
        } catch {
        }
    }

    private static func loadFromDefaults(defaults: UserDefaults, key: String) -> [Transaction] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Transaction].self, from: data)
        } catch {
            return []
        }
    }
}

extension Notification.Name {
    static let transactionsDidChange = Notification.Name("transactionsDidChange")
}

