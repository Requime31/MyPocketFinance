import SwiftUI

struct CategorySelectorView<Item: Identifiable & Hashable>: View {
    let categories: [Item]
    @Binding var selectedCategory: Item?

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    let titleProvider: (Item) -> String
    let iconProvider: (Item) -> (systemName: String, color: Color)

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(
        categories: [Item],
        selectedCategory: Binding<Item?>,
        title: @escaping (Item) -> String = { _ in "" },
        icon: @escaping (Item) -> (systemName: String, color: Color)
    ) {
        self.categories = categories
        self._selectedCategory = selectedCategory
        self.titleProvider = title
        self.iconProvider = icon
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing.m) {
            ForEach(categories) { category in
                let isSelected = category == selectedCategory
                let icon = iconProvider(category)

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        if isSelected {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                    }
                } label: {
                    VStack(spacing: spacing.s) {
                        ZStack {
                            Circle()
                                .fill(icon.color.opacity(isSelected ? 0.25 : 0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: icon.systemName)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(icon.color)
                        }

                        if !titleProvider(category).isEmpty {
                            Text(titleProvider(category))
                                .font(typography.caption.weight(.medium))
                                .foregroundStyle(colors.textPrimary)
                                .lineLimit(1)
                        }
                    }
                    .padding(spacing.s)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .fill(
                                isSelected
                                ? icon.color.opacity(0.12)
                                : colors.card
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                            .strokeBorder(
                                isSelected ? icon.color : colors.subtleBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .shadow(
                        color: isSelected ? icon.color.opacity(0.20) : .clear,
                        radius: 8, x: 0, y: 4
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    struct PreviewItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }

    let items = [
        PreviewItem(name: "Food"),
        PreviewItem(name: "Transport"),
        PreviewItem(name: "Shopping"),
        PreviewItem(name: "Bills"),
        PreviewItem(name: "Fun"),
        PreviewItem(name: "Other")
    ]

    return CategorySelectorView(
        categories: items,
        selectedCategory: .constant(nil),
        title: { $0.name },
        icon: { _ in ("fork.knife", .orange) }
    )
    .padding()
}

