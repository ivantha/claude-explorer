import SwiftUI

struct PopoverView: View {
    let viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Claude Explorer")
                    .font(.headline)
                Spacer()
                Button(action: { Task { await viewModel.refresh() } }) {
                    Image(systemName: viewModel.isRefreshing ? "arrow.trianglehead.2.clockwise" : "arrow.clockwise")
                        .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                        .animation(viewModel.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isRefreshing)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            if viewModel.hasData {
                ScrollView {
                    VStack(spacing: 16) {
                        UsageHeaderView(viewModel: viewModel)
                        Divider().padding(.horizontal)
                        TokenBreakdownView(viewModel: viewModel)
                        Divider().padding(.horizontal)
                        CostAndBurnView(viewModel: viewModel)
                        Divider().padding(.horizontal)
                        ModelBreakdownView(viewModel: viewModel)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Active Session")
                        .font(.title3.bold())
                    Text("Start using Claude Code to see usage data here.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                SettingsLink {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 320, height: 480)
    }
}
