import SwiftUI

struct ModelBreakdownView: View {
    let viewModel: UsageViewModel

    private var sortedModels: [(key: String, value: ModelStats)] {
        viewModel.snapshot.perModelStats
            .sorted { $0.value.totalInputOutput > $1.value.totalInputOutput }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per-Model Usage")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)

            if sortedModels.isEmpty {
                Text("No model data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 2) {
                    // Header
                    HStack {
                        Text("Model")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("In+Out")
                            .frame(width: 70, alignment: .trailing)
                        Text("Cost")
                            .frame(width: 60, alignment: .trailing)
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)

                    ForEach(sortedModels, id: \.key) { model, stats in
                        HStack {
                            Text(ModelPricing.displayName(for: model))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(stats.totalInputOutput.formatted())
                                .frame(width: 70, alignment: .trailing)
                            Text(String(format: "$%.2f", stats.costUSD))
                                .frame(width: 60, alignment: .trailing)
                        }
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}
