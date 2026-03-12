import SwiftUI

struct FAQView: View {
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    private struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private var items: [FAQItem] {
        [
            FAQItem(
                question: "How does MyPocketFinance track my goals?",
                answer: "Create savings goals and log contributions. We calculate your progress, project completion dates, and surface insights on the Dashboard and Goals screens."
            ),
            FAQItem(
                question: "Can I edit or delete transactions?",
                answer: "Yes. Open the Transactions or Dashboard views, tap a transaction, and use the edit options. You can safely adjust amounts, dates, and categories."
            ),
            FAQItem(
                question: "How are notifications used?",
                answer: "You can enable daily reminders and a weekly summary in Settings. We only send gentle nudges at the time you choose and you can turn them off anytime."
            ),
            FAQItem(
                question: "Is my data synced across devices?",
                answer: "In this version data is stored securely on your device. Future updates may add cloud sync; check the release notes for the latest information."
            ),
            FAQItem(
                question: "How do I contact support or share feedback?",
                answer: "From Settings, open Help & FAQ and tap Contact support. This creates an email draft where you can describe your issue or send feature requests."
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.l) {
                header

                ForEach(items) { item in
                    faqCard(for: item)
                }

                Spacer(minLength: spacing.xl)
            }
            .padding(spacing.l)
        }
        .background(colors.background.ignoresSafeArea())
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Answers to common questions")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            Text("Learn how goals, transactions, notifications, and privacy work in MyPocketFinance.")
                .font(typography.body)
                .foregroundStyle(colors.textSecondary)
        }
    }

    private func faqCard(for item: FAQItem) -> some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text(item.question)
                .font(typography.subtitle.weight(.semibold))
                .foregroundStyle(colors.textPrimary)

            Text(item.answer)
                .font(typography.body)
                .foregroundStyle(colors.textSecondary)
        }
        .padding(spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius.l,
                style: .continuous
            )
        )
        .shadow(
            color: colors.subtleBorder.opacity(0.9),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}

