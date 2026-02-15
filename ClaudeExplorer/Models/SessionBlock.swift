import Foundation

struct ModelStats {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationTokens: Int = 0
    var cacheReadTokens: Int = 0
    var costUSD: Double = 0.0

    var totalInputOutput: Int { inputTokens + outputTokens }
}

struct SessionBlock: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    var entries: [UsageEntry]

    var isActive: Bool {
        endTime > Date()
    }

    var totalInputTokens: Int {
        entries.reduce(0) { $0 + $1.inputTokens }
    }

    var totalOutputTokens: Int {
        entries.reduce(0) { $0 + $1.outputTokens }
    }

    var totalCacheCreationTokens: Int {
        entries.reduce(0) { $0 + $1.cacheCreationTokens }
    }

    var totalCacheReadTokens: Int {
        entries.reduce(0) { $0 + $1.cacheReadTokens }
    }

    var totalInputOutput: Int {
        totalInputTokens + totalOutputTokens
    }

    var costUSD: Double {
        entries.reduce(0.0) { total, entry in
            total + ModelPricing.cost(for: entry)
        }
    }

    var perModelStats: [String: ModelStats] {
        var stats: [String: ModelStats] = [:]
        for entry in entries {
            var ms = stats[entry.model, default: ModelStats()]
            ms.inputTokens += entry.inputTokens
            ms.outputTokens += entry.outputTokens
            ms.cacheCreationTokens += entry.cacheCreationTokens
            ms.cacheReadTokens += entry.cacheReadTokens
            ms.costUSD += ModelPricing.cost(for: entry)
            stats[entry.model] = ms
        }
        return stats
    }

    var timeUntilReset: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }

    var burnRateTokensPerMin: Double {
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = max(elapsed / 60.0, 1.0)
        return Double(totalInputOutput) / minutes
    }
}
