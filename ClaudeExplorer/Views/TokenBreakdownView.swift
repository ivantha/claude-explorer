import SwiftUI

struct TokenBreakdownView: View {
    let viewModel: UsageViewModel

    var body: some View {
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
