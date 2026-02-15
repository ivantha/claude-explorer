import Foundation

enum PlanType: String, CaseIterable, Identifiable {
    case pro = "Pro"
    case max5 = "Max (5x)"
    case max20 = "Max (20x)"

    var id: String { rawValue }

    /// Token limit (input + output) per 5-hour window
    var tokenLimit: Int {
        switch self {
        case .pro: return 19_000
        case .max5: return 88_000
        case .max20: return 220_000
        }
    }
}

struct ModelPricing {
    struct Prices {
        let inputPerMillion: Double
        let outputPerMillion: Double
        let cacheWritePerMillion: Double
        let cacheReadPerMillion: Double
    }

    static let pricing: [String: Prices] = [
        "opus": Prices(inputPerMillion: 15.0, outputPerMillion: 75.0,
                       cacheWritePerMillion: 18.75, cacheReadPerMillion: 1.50),
        "sonnet": Prices(inputPerMillion: 3.0, outputPerMillion: 15.0,
                         cacheWritePerMillion: 3.75, cacheReadPerMillion: 0.30),
        "haiku": Prices(inputPerMillion: 0.25, outputPerMillion: 1.25,
                        cacheWritePerMillion: 0.30, cacheReadPerMillion: 0.03),
    ]

    static func modelFamily(for modelString: String) -> String {
        let lower = modelString.lowercased()
        if lower.contains("opus") { return "opus" }
        if lower.contains("haiku") { return "haiku" }
        return "sonnet" // default to sonnet
    }

    static func displayName(for modelString: String) -> String {
        let lower = modelString.lowercased()
        if lower.contains("opus") { return "Opus" }
        if lower.contains("haiku") { return "Haiku" }
        if lower.contains("sonnet") { return "Sonnet" }
        return modelString
    }

    static func prices(for modelString: String) -> Prices {
        let family = modelFamily(for: modelString)
        return pricing[family] ?? pricing["sonnet"]!
    }

    static func cost(for entry: UsageEntry) -> Double {
        let p = prices(for: entry.model)
        let inputCost = Double(entry.inputTokens) / 1_000_000.0 * p.inputPerMillion
        let outputCost = Double(entry.outputTokens) / 1_000_000.0 * p.outputPerMillion
        let cacheWriteCost = Double(entry.cacheCreationTokens) / 1_000_000.0 * p.cacheWritePerMillion
        let cacheReadCost = Double(entry.cacheReadTokens) / 1_000_000.0 * p.cacheReadPerMillion
        return inputCost + outputCost + cacheWriteCost + cacheReadCost
    }
}
