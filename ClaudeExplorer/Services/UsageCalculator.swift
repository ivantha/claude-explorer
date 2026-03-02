import Foundation

enum DataSource: String, CaseIterable, Identifiable, Sendable {
    case api = "API"
    case local = "Local"

    var id: String { rawValue }
}

struct UsageSnapshot: Sendable {
    let dataSource: DataSource
    let usagePercent: Double
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheCreationTokens: Int
    let totalCacheReadTokens: Int
    let totalInputOutput: Int
    let costUSD: Double
    let burnRateTokensPerMin: Double
    let perModelStats: [String: ModelStats]
    let blockStartTime: Date
    let blockEndTime: Date
    let planLimit: Int

    // API-only fields
    let sevenDayUtilization: Double?
    let sevenDayResetsAt: Date?
    let sevenDayOpusUtilization: Double?
    let sevenDaySonnetUtilization: Double?
    let subscriptionType: String?

    static let empty = UsageSnapshot(
        dataSource: .local,
        usagePercent: 0,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalCacheCreationTokens: 0,
        totalCacheReadTokens: 0,
        totalInputOutput: 0,
        costUSD: 0,
        burnRateTokensPerMin: 0,
        perModelStats: [:],
        blockStartTime: Date(),
        blockEndTime: Date(),
        planLimit: 0,
        sevenDayUtilization: nil,
        sevenDayResetsAt: nil,
        sevenDayOpusUtilization: nil,
        sevenDaySonnetUtilization: nil,
        subscriptionType: nil
    )

    static func fromAPI(_ response: APIUsageResponse, credentials: ClaudeCredentials) -> UsageSnapshot {
        UsageSnapshot(
            dataSource: .api,
            usagePercent: response.fiveHour.utilization,
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCacheCreationTokens: 0,
            totalCacheReadTokens: 0,
            totalInputOutput: 0,
            costUSD: 0,
            burnRateTokensPerMin: 0,
            perModelStats: [:],
            blockStartTime: Date(),
            blockEndTime: response.fiveHour.resetsAtDate ?? Date(),
            planLimit: 0,
            sevenDayUtilization: response.sevenDay.utilization,
            sevenDayResetsAt: response.sevenDay.resetsAtDate,
            sevenDayOpusUtilization: response.sevenDayOpus?.utilization,
            sevenDaySonnetUtilization: response.sevenDaySonnet?.utilization,
            subscriptionType: credentials.subscriptionType
        )
    }
}

final class UsageCalculator {
    func calculate(block: SessionBlock, plan: PlanType) -> UsageSnapshot {
        let totalIO = block.totalInputOutput
        let percent = min(Double(totalIO) / Double(plan.tokenLimit) * 100.0, 100.0)

        return UsageSnapshot(
            dataSource: .local,
            usagePercent: percent,
            totalInputTokens: block.totalInputTokens,
            totalOutputTokens: block.totalOutputTokens,
            totalCacheCreationTokens: block.totalCacheCreationTokens,
            totalCacheReadTokens: block.totalCacheReadTokens,
            totalInputOutput: totalIO,
            costUSD: block.costUSD,
            burnRateTokensPerMin: block.burnRateTokensPerMin,
            perModelStats: block.perModelStats,
            blockStartTime: block.startTime,
            blockEndTime: block.endTime,
            planLimit: plan.tokenLimit,
            sevenDayUtilization: nil,
            sevenDayResetsAt: nil,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            subscriptionType: nil
        )
    }
}
