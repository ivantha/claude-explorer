import SwiftUI

struct CostAndBurnView: View {
    let viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Stats")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)

            HStack(spacing: 16) {
                statCard(
                    title: "Cost",
                    value: viewModel.costFormatted,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                statCard(
                    title: "Burn Rate",
                    value: viewModel.burnRateFormatted,
                    icon: "flame.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.callout.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
