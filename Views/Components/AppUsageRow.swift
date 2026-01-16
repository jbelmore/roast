import SwiftUI

struct AppUsageRow: View {
    let app: AppUsageStat

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.callout)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("\(app.sessions) sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if app.briefVisits > 0 {
                        Text("\(app.briefVisits) quick")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Text(TimeFormatters.formatDuration(app.totalTime))
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

struct AppUsageRowWithStats: View {
    let stat: AppUsageStats

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.appName)
                    .font(.callout)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("\(stat.totalSessions) sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("avg \(stat.formattedAvgSession)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if stat.briefVisits > 0 {
                        Text("\(stat.briefVisits) quick")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Text(stat.formattedTotalTime)
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack {
        AppUsageRow(app: AppUsageStat(
            appName: "Xcode",
            bundleID: "com.apple.Xcode",
            totalTime: 3600,
            sessions: 5,
            briefVisits: 2
        ))
    }
    .padding()
}
