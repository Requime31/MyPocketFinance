import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @State private var isPresentingAdd = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.transactions.isEmpty {
                    EmptyStateView(
                        iconName: "tray",
                        title: "No transactions yet",
                        message: "Once you start adding transactions, your history will appear here.",
                        primaryActionTitle: "Add first transaction",
                        primaryAction: { isPresentingAdd = true }
                    )
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.transactions) { transaction in
                            Button {
                                selectedTransaction = transaction
                            } label: {
                                TransactionRow(transaction: transaction)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            indexSet
                                .map { viewModel.transactions[$0] }
                                .forEach(viewModel.delete)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddTransactionView { transaction in
                    InMemoryTransactionService.shared.add(transaction)
                    viewModel.load()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(
                    transaction: transaction,
                    onUpdate: { updated in
                        viewModel.update(updated)
                    },
                    onDelete: { deleted in
                        viewModel.delete(deleted)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    TransactionsView()
}

