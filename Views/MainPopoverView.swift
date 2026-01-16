import SwiftUI

struct MainPopoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: NavigationTab = .today

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "eye.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Roast")
                    .font(.headline)
                Spacer()

                // Monitoring indicator
                if appState.isMonitoring {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .help("Monitoring active")
                } else {
                    Circle()
                        .fill(.gray)
                        .frame(width: 8, height: 8)
                        .help("Monitoring paused")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Tab bar
            HStack(spacing: 0) {
                ForEach(NavigationTab.allCases, id: \.self) { tab in
                    TabButton(tab: tab, selectedTab: $selectedTab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .today:
                    TodayView()
                case .weeklyReport:
                    WeeklyReportView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 500)
    }
}

struct TabButton: View {
    let tab: NavigationTab
    @Binding var selectedTab: NavigationTab

    var isSelected: Bool {
        selectedTab == tab
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                Text(tab.rawValue)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainPopoverView()
        .environmentObject(AppState.shared)
}
