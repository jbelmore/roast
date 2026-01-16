import SwiftUI

struct HistoryView: View {
    @State private var reports: [WeeklyReport] = []
    @State private var selectedReport: WeeklyReport?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading history...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reports.isEmpty {
                EmptyHistoryView()
            } else {
                List(selection: $selectedReport) {
                    ForEach(reports) { report in
                        ReportListRow(report: report)
                            .tag(report)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onAppear {
            loadReports()
        }
        .sheet(item: $selectedReport) { report in
            ReportDetailSheet(report: report)
        }
    }

    private func loadReports() {
        isLoading = true
        Task {
            do {
                let loadedReports = try DatabaseManager.shared.getWeeklyReports(limit: 20)
                await MainActor.run {
                    reports = loadedReports
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No reports yet")
                .font(.headline)

            Text("Your weekly reports will appear here after you generate them.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Report List Row

struct ReportListRow: View {
    let report: WeeklyReport

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TimeFormatters.formatDateRange(
                    start: report.weekStartDate,
                    end: report.weekEndDate
                ))
                .font(.callout)
                .fontWeight(.medium)

                if let stats = report.weekStats {
                    HStack(spacing: 8) {
                        Label("\(stats.totalContextSwitches) switches", systemImage: "arrow.triangle.swap")
                        Label("\(stats.totalDeepWorkMinutes)m focus", systemImage: "brain")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Report Detail Sheet

struct ReportDetailSheet: View {
    let report: WeeklyReport
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Report")
                        .font(.headline)

                    Text(TimeFormatters.formatDateRange(
                        start: report.weekStartDate,
                        end: report.weekEndDate
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let stats = report.weekStats {
                        WeeklyStatsSummary(stats: stats)
                        Divider()
                    }

                    Text("Analysis")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    MarkdownView(text: report.aiAnalysis)
                }
                .padding()
            }
        }
        .frame(width: 450, height: 600)
    }
}

#Preview {
    HistoryView()
        .frame(width: 400, height: 500)
}
