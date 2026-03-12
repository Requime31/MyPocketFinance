import Foundation
import Combine

final class TransactionViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []

    private let transactionService: TransactionService

    init(transactionService: TransactionService = InMemoryTransactionService.shared) {
        self.transactionService = transactionService
        load()
    }

    func load() {
        transactions = transactionService.fetchTransactions()
    }

    func delete(_ transaction: Transaction) {
        transactionService.delete(transaction)
        load()
    }

    func update(_ transaction: Transaction) {
        transactionService.update(transaction)
        load()
    }
}

