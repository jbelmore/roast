import SwiftUI

struct MiniBarChart: View {
    let apps: [AppUsageStats]

    private var maxTime: TimeInterval {
        apps.map { $0.totalTime }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(apps) { app in
                HStack(spacing: 8) {
                    Text(app.appName)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geometry in
                        let barWidth = geometry.size.width * CGFloat(app.totalTime / maxTime)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: max(barWidth, 4))
                    }
                    .frame(height: 12)

                    Text(app.formattedTotalTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
    }
}

struct MiniBarChartSimple: View {
    let data: [(label: String, value: Double, color: Color)]

    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(data.indices, id: \.self) { index in
                let item = data[index]
                HStack(spacing: 8) {
                    Text(item.label)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geometry in
                        let barWidth = geometry.size.width * CGFloat(item.value / maxValue)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.color.opacity(0.7))
                            .frame(width: max(barWidth, 4))
                    }
                    .frame(height: 12)
                }
            }
        }
    }
}

#Preview {
    VStack {
        MiniBarChartSimple(data: [
            ("Xcode", 3600, .blue),
            ("Safari", 1800, .orange),
            ("Slack", 900, .purple)
        ])
    }
    .padding()
    .frame(width: 300)
}
