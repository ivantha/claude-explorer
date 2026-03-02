import Foundation
import SwiftUI
import Combine

enum DataMode: String, CaseIterable, Identifiable, Sendable {
    case auto = "Auto"
    case api = "API Only"
    case local = "Local Only"

    var id: String { rawValue }
}

enum CredentialStatus: Sendable {
    case unknown
    case available
    case expired
    case missing
    case apiError(String)
}

@MainActor
@Observable
final class UsageViewModel {
    // MARK: - Published State
    var snapshot: UsageSnapshot = .empty
    var hasData: Bool = false
    var isRefreshing: Bool = false
    var tick: UInt64 = 0
    var credentialStatus: CredentialStatus = .unknown

    // MARK: - Settings (persisted via UserDefaults)
    var selectedPlan: PlanType = .max20
    var refreshInterval: TimeInterval = 30
    var dataMode: DataMode = .auto

    // MARK: - Private
    private let reader = JSONLReader()
    private let analyzer = SessionAnalyzer()
    private let calculator = UsageCalculator()
    private let credentialReader = CredentialReader()
    private let apiFetcher = APIUsageFetcher()
    private var timer: Timer?
    private var displayTimer: Timer?
    private var isMonitoring = false

    init() {
        if let raw = UserDefaults.standard.string(forKey: "selectedPlan"),
           let plan = PlanType(rawValue: raw) {
            selectedPlan = plan
        }
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        if interval > 0 {
            refreshInterval = interval
        }
        if let raw = UserDefaults.standard.string(forKey: "dataMode"),
           let mode = DataMode(rawValue: raw) {
            dataMode = mode
        }
    }

    // MARK: - Menu Bar Text
    var menuBarDisplayText: String {
        // Access tick to force SwiftUI re-evaluation
        _ = tick
        guard hasData else { return "--% · --:--" }
        let pct = "\(Int(snapshot.usagePercent))%"
        let remaining = snapshot.blockEndTime.timeIntervalSince(Date())
        if remaining > 0 {
            return "\(pct) · \(formatDuration(remaining))"
        }
        return pct
    }

    var usagePercentFormatted: String {
        guard hasData else { return "--%"}
        return String(format: "%.1f%%", snapshot.usagePercent)
    }

    var timeUntilResetFormatted: String {
        _ = tick
        guard hasData else { return "No active session" }
        let remaining = snapshot.blockEndTime.timeIntervalSince(Date())
        guard remaining > 0 else { return "No active session" }
        return "Resets in \(formatDuration(remaining))"
    }

    var costFormatted: String {
        String(format: "$%.2f", snapshot.costUSD)
    }

    var burnRateFormatted: String {
        String(format: "%.1f tokens/min", snapshot.burnRateTokensPerMin)
    }

    var progressColor: Color {
        let pct = snapshot.usagePercent
        if pct > 95 { return .red }
        if pct > 80 { return .orange }
        if pct > 50 { return .yellow }
        return .green
    }

    var tokenLimitFormatted: String {
        let limit = selectedPlan.tokenLimit
        if limit >= 1000 {
            return "\(limit / 1000)K"
        }
        return "\(limit)"
    }

    var isAPIMode: Bool {
        snapshot.dataSource == .api
    }

    var dataSourceLabel: String {
        switch snapshot.dataSource {
        case .api: return "Live"
        case .local: return "Local"
        }
    }

    var credentialStatusText: String {
        switch credentialStatus {
        case .unknown: return "Checking..."
        case .available: return "Connected"
        case .expired: return "Token expired — run claude to refresh"
        case .missing: return "No credentials found"
        case .apiError(let msg): return msg
        }
    }

    // MARK: - Actions

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        Task { await refresh() }
        startTimer()
        startDisplayTimer()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        displayTimer?.invalidate()
        displayTimer = nil
        isMonitoring = false
    }

    func changePlan(_ plan: PlanType) {
        selectedPlan = plan
        UserDefaults.standard.set(plan.rawValue, forKey: "selectedPlan")
        recalculate()
    }

    func changeRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
        UserDefaults.standard.set(interval, forKey: "refreshInterval")
        startTimer()
    }

    func changeDataMode(_ mode: DataMode) {
        dataMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "dataMode")
        Task { await refresh() }
    }

    func refresh() async {
        isRefreshing = true

        switch dataMode {
        case .auto:
            if await tryAPIRefresh() {
                isRefreshing = false
                return
            }
            await localRefresh()
        case .api:
            if await tryAPIRefresh() {
                isRefreshing = false
                return
            }
            // API-only mode: show no data on failure
            snapshot = .empty
            hasData = false
        case .local:
            await localRefresh()
        }

        isRefreshing = false
    }

    // MARK: - Private

    private func tryAPIRefresh() async -> Bool {
        let credentials: ClaudeCredentials
        do {
            credentials = try credentialReader.read()
        } catch {
            credentialStatus = .missing
            return false
        }

        if credentials.isExpired {
            credentialStatus = .expired
            return false
        }

        do {
            let response = try await apiFetcher.fetch(accessToken: credentials.accessToken)
            snapshot = UsageSnapshot.fromAPI(response, credentials: credentials)
            hasData = true
            credentialStatus = .available
            return true
        } catch let error as APIUsageError {
            credentialStatus = .apiError(error.localizedDescription)
            return false
        } catch {
            credentialStatus = .apiError(error.localizedDescription)
            return false
        }
    }

    private func localRefresh() async {
        let cutoff = Date().addingTimeInterval(-5 * 60 * 60) // last 5 hours
        let entries = await reader.readEntries(since: cutoff)
        let blocks = analyzer.analyze(entries: entries)

        if let active = analyzer.activeBlock(from: blocks) {
            snapshot = calculator.calculate(block: active, plan: selectedPlan)
            hasData = true
        } else {
            snapshot = .empty
            hasData = false
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick &+= 1
            }
        }
    }

    private func recalculate() {
        Task { await refresh() }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
