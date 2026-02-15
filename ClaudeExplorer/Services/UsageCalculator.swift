import Foundation

struct UsageSnapshot {
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

    static let empty = UsageSnapshot(
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
        planLimit: 0
    )
}

final class UsageCalculator {
    func calculate(block: SessionBlock, plan: PlanType) -> UsageSnapshot {
        let totalIO = block.totalInputOutput
        let percent = min(Double(totalIO) / Double(plan.tokenLimit) * 100.0, 100.0)

        return UsageSnapshot(
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
            planLimit: plan.tokenLimit
        )
    }
}
