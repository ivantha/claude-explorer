import Foundation

struct UsageEntry: Identifiable {
    let id: String // messageId:requestId for deduplication
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int

    var totalInputOutput: Int {
        inputTokens + outputTokens
    }

    var totalAllTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
}
