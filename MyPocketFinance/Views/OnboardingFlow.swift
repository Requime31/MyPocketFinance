import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var onCompleted: () -> Void

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    colors.background,
                    colors.background.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $viewModel.currentPageIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: viewModel.currentPageIndex == index)
                            .tag(index)
                            .padding(.horizontal, spacing.l)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.9), value: viewModel.currentPageIndex)

                footer
                    .padding(.horizontal, spacing.l)
                    .padding(.bottom, spacing.xl)
                    .padding(.top, spacing.l)
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()

            if !viewModel.isLastPage {
                Button("Skip") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        viewModel.skip()
                    }
                    onCompleted()
                }
                .font(typography.body)
                .foregroundStyle(colors.textSecondary)
            }
        }
        .padding(.top, spacing.xl)
        .padding(.horizontal, spacing.l)
    }

    private var footer: some View {
        VStack(spacing: spacing.m * 1.5) {
            HStack(spacing: spacing.s) {
                ForEach(0..<viewModel.pages.count, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == viewModel.currentPageIndex ? colors.accent : colors.textSecondary.opacity(0.18))
                        .frame(width: index == viewModel.currentPageIndex ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentPageIndex)
                }
            }

            PrimaryButton(title: viewModel.isLastPage ? "Get Started" : "Next") {
                if viewModel.isLastPage {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                        viewModel.finish()
                    }
                    onCompleted()
                } else {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                        viewModel.goToNextPage()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onCompleted: {})
}

