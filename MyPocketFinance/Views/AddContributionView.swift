import SwiftUI

struct AddContributionView: View {
    let goal: Goal
    var onSave: (_ amount: Decimal, _ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing

    @State private var amountText: String = ""
    @State private var note: String = ""

    private var isSaveDisabled: Bool {
        Decimal(string: amountText) == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contribution")) {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.numberPad)
                        .onChange(of: amountText, initial: false) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                amountText = filtered
                            }
                        }

                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("Add to \(goal.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func save() {
        let amount = Decimal(string: amountText) ?? 0
        guard amount > 0 else { return }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = trimmedNote.isEmpty ? nil : trimmedNote

        onSave(amount, finalNote)
        dismiss()
    }
}

