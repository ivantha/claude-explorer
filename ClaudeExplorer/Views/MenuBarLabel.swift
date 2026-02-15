import SwiftUI

struct MenuBarLabel: View {
    let viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.medium")
            Text(viewModel.menuBarDisplayText)
                .monospacedDigit()
        }
        .task {
            viewModel.startMonitoring()
        }
    }
}
