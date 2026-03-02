import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let viewModel: UsageViewModel
    @State private var selectedPlan: PlanType = .max20
    @State private var refreshSeconds: Double = 30
    @State private var launchAtLogin: Bool = false
    @State private var selectedDataMode: DataMode = .auto

    var body: some View {
        Form {
            Section("Data Source") {
                Picker("Mode", selection: $selectedDataMode) {
                    ForEach(DataMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .onChange(of: selectedDataMode) { _, newValue in
                    viewModel.changeDataMode(newValue)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(credentialDotColor)
                        .frame(width: 8, height: 8)
                    Text(viewModel.credentialStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if selectedDataMode == .local {
                Section("Plan") {
                    Picker("Subscription Plan", selection: $selectedPlan) {
                        ForEach(PlanType.allCases) { plan in
                            Text("\(plan.rawValue) — \(plan.tokenLimit.formatted()) tokens/5h")
                                .tag(plan)
                        }
                    }
                    .onChange(of: selectedPlan) { _, newValue in
                        viewModel.changePlan(newValue)
                    }
                }
            }

            Section("Refresh") {
                HStack {
                    Text("Interval: \(Int(refreshSeconds))s")
                    Slider(value: $refreshSeconds, in: 10...120, step: 10)
                }
                .onChange(of: refreshSeconds) { _, newValue in
                    viewModel.changeRefreshInterval(newValue)
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
        .onAppear {
            selectedPlan = viewModel.selectedPlan
            refreshSeconds = viewModel.refreshInterval
            selectedDataMode = viewModel.dataMode
        }
    }

    private var credentialDotColor: Color {
        switch viewModel.credentialStatus {
        case .available: return .green
        case .expired: return .orange
        case .missing, .apiError: return .red
        case .unknown: return .gray
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}
