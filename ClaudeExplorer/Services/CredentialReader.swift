import Foundation

struct ClaudeCredentials: Sendable {
    let accessToken: String
    let expiresAt: Date
    let subscriptionType: String?
    let rateLimitTier: String?

    var isExpired: Bool {
        expiresAt < Date()
    }
}

final class CredentialReader: Sendable {
    private struct CredentialsFile: Codable {
        let claudeAiOauth: OAuthSection

        struct OAuthSection: Codable {
            let accessToken: String
            let expiresAt: Double
            let subscriptionType: String?
            let rateLimitTier: String?
        }
    }

    private static let credentialsPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/.credentials.json"
    }()

    func read() throws -> ClaudeCredentials {
        let url = URL(fileURLWithPath: Self.credentialsPath)
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(CredentialsFile.self, from: data)
        let oauth = file.claudeAiOauth
        let expiresAt = Date(timeIntervalSince1970: oauth.expiresAt / 1000.0)

        return ClaudeCredentials(
            accessToken: oauth.accessToken,
            expiresAt: expiresAt,
            subscriptionType: oauth.subscriptionType,
            rateLimitTier: oauth.rateLimitTier
        )
    }
}
