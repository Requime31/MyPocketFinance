import SwiftUI

struct MainTabView: View {
    @Environment(\.appColors) private var colors
    @State private var isPresentingAddTransaction = false
    @State private var selectedTab: Tab = .dashboard

    private enum Tab: Hashable {
        case dashboard
        case goals
        case reports
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .goals: return "Goals"
            case .reports: return "Statistics"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: return "rectangle.grid.2x2.fill"
            case .goals: return "target"
            case .reports: return "chart.bar.xaxis"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView {
                    isPresentingAddTransaction = true
                }
                .navigationTitle("Dashboard")
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .tag(Tab.dashboard)
            .tabItem {
                tabLabel(for: .dashboard)
            }

            NavigationStack {
                GoalsView()
                    .navigationTitle("Goals")
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .tag(Tab.goals)
            .tabItem {
                tabLabel(for: .goals)
            }

            NavigationStack {
                ReportsView()
                    .navigationTitle("Statistics")
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .tag(Tab.reports)
            .tabItem {
                tabLabel(for: .reports)
            }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .tag(Tab.settings)
            .tabItem {
                tabLabel(for: .settings)
            }
        }
        .tint(colors.accent)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: selectedTab)
        .sheet(isPresented: $isPresentingAddTransaction) {
            AddTransactionView { transaction in
                InMemoryTransactionService.shared.add(transaction)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func tabLabel(for tab: Tab) -> some View {
        let isActive = selectedTab == tab

        VStack(spacing: 4) {
            Image(systemName: tab.systemImage)
                .symbolVariant(isActive ? .fill : .none)
                .scaleEffect(isActive ? 1.08 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isActive)

            Text(tab.title)
        }
    }
}

#Preview {
    MainTabView()
}

