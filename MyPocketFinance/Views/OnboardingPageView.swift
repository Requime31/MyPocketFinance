import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var illustrationScale: CGFloat = 0.9
    @State private var illustrationOffset: CGFloat = 40
    @State private var textOpacity: Double = 0.0

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            VStack(spacing: spacing.xl * 1.6) {
                Spacer(minLength: spacing.l)

                ZStack {
                    RoundedRectangle(cornerRadius: size.width * 0.5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: page.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.width * 0.7, height: size.width * 0.7)
                        .shadow(color: colors.primary.opacity(0.25), radius: 24, x: 0, y: 18)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.5)
                                .blur(radius: 0.5)
                                .padding(24)
                        )

                    Image(systemName: page.systemImageName)
                        .font(.system(size: size.width * 0.24, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                }
                .scaleEffect(illustrationScale)
                .offset(y: illustrationOffset)

                VStack(spacing: spacing.s * 1.5) {
                    Text(page.title)
                        .font(typography.largeTitle)
                        .foregroundStyle(colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(page.subtitle)
                        .font(typography.body)
                        .foregroundStyle(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, spacing.xl * 1.2)
                }
                .opacity(textOpacity)

                Spacer()
            }
            .frame(width: size.width, height: size.height)
        }
        .onAppear {
            if isActive {
                animateIn()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animateIn()
            }
        }
    }

    private func animateIn() {
        illustrationScale = 0.9
        illustrationOffset = 40
        textOpacity = 0.0

        withAnimation(.spring(response: 0.7, dampingFraction: 0.85, blendDuration: 0.2)) {
            illustrationScale = 1.0
            illustrationOffset = 0
        }

        withAnimation(.easeOut(duration: 0.35).delay(0.15)) {
            textOpacity = 1.0
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.97, blue: 1.00),
                Color(red: 0.90, green: 0.94, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        OnboardingPageView(
            page: OnboardingPage(
                title: "Take Control of Your Money",
                subtitle: "Track expenses and understand where your money goes",
                systemImageName: "chart.pie.fill",
                gradient: [
                    Color(red: 0.30, green: 0.63, blue: 0.83),
                    Color(red: 0.39, green: 0.40, blue: 0.74)
                ]
            ),
            isActive: true
        )
        .padding(.horizontal, 24)
    }
}

