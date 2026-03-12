import SwiftUI

struct SurfaceCard<Content: View>: View {
    let content: Content

    @Environment(\.appColors) private var colors
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .stroke(colors.subtleBorder, lineWidth: 1)
            )
            .shadow(color: colors.subtleBorder.opacity(0.6), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    SurfaceCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Surface card")
            Text("Reusable neutral container")
                .font(.caption)
        }
    }
    .padding(24)
}

