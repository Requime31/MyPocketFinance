import SwiftUI

struct PrimaryButton: View {
    let title: String
    var action: () -> Void

    var leadingSymbol: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            guard isEnabled, !isLoading else { return }

            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }

            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(colors.onHero)
                        .progressViewStyle(.circular)
                } else {
                    HStack(spacing: spacing.s) {
                        if let leadingSymbol {
                            Image(systemName: leadingSymbol)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Text(title)
                            .font(typography.subtitle)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, spacing.m)
            .padding(.horizontal, spacing.l)
            .foregroundStyle(colors.onHero)
            .background(
                LinearGradient(
                    colors: colors.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .strokeBorder(colors.onHero.opacity(0.18), lineWidth: 1)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius.l,
                    style: .continuous
                )
            )
            .shadow(color: colors.primary.opacity(0.32), radius: 18, x: 0, y: 10)
            .opacity(isEnabled ? 1 : 0.6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", action: {})
        PrimaryButton(title: "Get Started", action: {}, leadingSymbol: "arrow.right")
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
    }
    .padding(24)
}

