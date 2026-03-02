import SwiftUI

struct TokenBreakdownView: View {
    let viewModel: UsageViewModel

    var body: some View {
        if viewModel.isAPIMode {
            apiView
        } else {
            localView
        }
    }

    // MARK: - API Mode: Usage Windows

    private var apiView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usage Windows")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)

            VStack(spacing: 6) {
                windowRow(
                    label: "5-hour",
                    utilization: viewModel.snapshot.usagePercent,
                    color: viewModel.progressColor
                )
                if let sevenDay = viewModel.snapshot.sevenDayUtilization {
                    windowRow(
                        label: "7-day",
                        utilization: sevenDay,
                        color: colorForPercent(sevenDay)
                    )
                }
                if let opus = viewModel.snapshot.sevenDayOpusUtilization {
                    windowRow(
                        label: "7-day Opus",
                        utilization: opus,
                        color: colorForPercent(opus)
                    )
                }
                if let sonnet = viewModel.snapshot.sevenDaySonnetUtilization {
                    windowRow(
                        label: "7-day Sonnet",
                        utilization: sonnet,
                        color: colorForPercent(sonnet)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func windowRow(label: String, utilization: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.0f%%", utilization))
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.gradient)
                        .frame(width: max(0, geo.size.width * min(utilization / 100.0, 1.0)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func colorForPercent(_ pct: Double) -> Color {
        if pct > 95 { return .red }
        if pct > 80 { return .orange }
        if pct > 50 { return .yellow }
        return .green
    }

    // MARK: - Local Mode: Token Rows

    private var localView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Token Breakdown")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)

            VStack(spacing: 4) {
                tokenRow(label: "Input", count: viewModel.snapshot.totalInputTokens, icon: "arrow.down.circle.fill", color: .blue)
                tokenRow(label: "Output", count: viewModel.snapshot.totalOutputTokens, icon: "arrow.up.circle.fill", color: .purple)
                tokenRow(label: "Cache Write", count: viewModel.snapshot.totalCacheCreationTokens, icon: "square.and.arrow.down.fill", color: .orange)
                tokenRow(label: "Cache Read", count: viewModel.snapshot.totalCacheReadTokens, icon: "square.and.arrow.up.fill", color: .green)
            }
            .padding(.horizontal, 16)
        }
    }

    private func tokenRow(label: String, count: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
            Spacer()
            Text(count.formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
