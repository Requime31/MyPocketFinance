import SwiftUI

struct EditGoalView: View {
    let goal: Goal
    var onSave: (_ name: String, _ targetAmount: Decimal, _ dueDate: Date?, _ category: GoalCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var targetAmountText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var category: GoalCategory

    init(goal: Goal, onSave: @escaping (_ name: String, _ targetAmount: Decimal, _ dueDate: Date?, _ category: GoalCategory) -> Void) {
        self.goal = goal
        self.onSave = onSave
        _name = State(initialValue: goal.name)
        _targetAmountText = State(initialValue: (goal.targetAmount as NSDecimalNumber).stringValue)
        _hasDueDate = State(initialValue: goal.dueDate != nil)
        _dueDate = State(initialValue: goal.dueDate ?? Date())
        _category = State(initialValue: goal.category)
    }

    private var parsedTarget: Decimal? {
        AmountFieldParsing.decimal(from: targetAmountText)
    }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        parsedTarget.map { $0 <= 0 } ?? true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Goal details")) {
                    TextField("Goal name", text: $name)

                    TextField("Target amount", text: $targetAmountText)
                        .keyboardType(.decimalPad)

                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases) { category in
                            Text(category.title)
                                .tag(category)
                        }
                    }
                }

                Section(header: Text("Timeline")) {
                    Toggle("Set target date", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker(
                            "Estimated completion",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Edit Goal")
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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let targetAmount = parsedTarget, targetAmount > 0 else { return }
        let date = hasDueDate ? dueDate : nil

        onSave(trimmedName, targetAmount, date, category)
        dismiss()
    }
}

