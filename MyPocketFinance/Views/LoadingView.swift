import SwiftUI

struct LoadingView: View {
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @State private var animatePulse: Bool = false
    @State private var animateGlow: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    colors.background,
                    colors.background.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: spacing.l * 1.5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colors.primaryGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(animatePulse ? 1.04 : 0.98)
                        .shadow(
                            color: colors.accent.opacity(animateGlow ? 0.45 : 0.18),
                            radius: animateGlow ? 36 : 18,
                            x: 0,
                            y: 18
                        )

                    VStack(spacing: 6) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .foregroundStyle(colors.onHero)

                        Text("MyPocket")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(colors.onHeroSecondary)
                    }
                }

                VStack(spacing: spacing.s) {
                    Text("Preparing your insights")
                        .font(typography.subtitle)
                        .foregroundStyle(colors.textPrimary)

                    ShimmeringProgressDots()
                }
                .padding(.horizontal, spacing.l)
            }
        }
        .onAppear {
            withAnimation(
                .spring(response: 1.0, dampingFraction: 0.85)
                .repeatForever(autoreverses: true)
            ) {
                animatePulse = true
            }

            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
            ) {
                animateGlow = true
            }
        }
    }
}

private struct ShimmeringProgressDots: View {
    @Environment(\.appColors) private var colors
    @Environment(\.appSpacing) private var spacing
    @State private var activeIndex: Int = 0

    private let dotCount = 3

    var body: some View {
        HStack(spacing: spacing.s) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(colors.accent)
                    .frame(width: 8, height: 8)
                    .opacity(activeIndex == index ? 1.0 : 0.25)
                    .scaleEffect(activeIndex == index ? 1.2 : 0.9)
                    .animation(
                        .easeInOut(duration: 0.45),
                        value: activeIndex
                    )
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                activeIndex = (activeIndex + 1) % dotCount
            }
        }
    }
}

#Preview {
    LoadingView()
        .environment(\.appColors, .light)
}

