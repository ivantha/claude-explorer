import SwiftUI

struct UsageHeaderView: View {
    let viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Big percentage
            Text(viewModel.usagePercentFormatted)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(viewModel.progressColor)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewModel.progressColor.gradient)
                        .frame(width: max(0, geo.size.width * min(viewModel.snapshot.usagePercent / 100.0, 1.0)), height: 12)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.snapshot.usagePercent)
                }
            }
            .frame(height: 12)

            // Subtitle: differs by mode
            if viewModel.isAPIMode {
                HStack {
                    Text("5-hour utilization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let sub = viewModel.snapshot.subscriptionType {
                        Text(sub.capitalized)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("\(viewModel.snapshot.totalInputOutput.formatted()) tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.tokenLimitFormatted) limit (\(viewModel.selectedPlan.rawValue))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Reset timer
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(viewModel.timeUntilResetFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }
}
