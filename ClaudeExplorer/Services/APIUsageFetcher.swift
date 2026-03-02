import Foundation

enum APIUsageError: Error, Sendable {
    case tokenExpired
    case unauthorized
    case rateLimited
    case httpError(Int)
    case networkError(Error)

    var localizedDescription: String {
        switch self {
        case .tokenExpired: return "Token expired — run claude to refresh"
        case .unauthorized: return "Unauthorized — run claude to re-authenticate"
        case .rateLimited: return "Rate limited — try again shortly"
        case .httpError(let code): return "HTTP error \(code)"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

final class APIUsageFetcher: Sendable {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    func fetch(accessToken: String) async throws -> APIUsageResponse {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIUsageError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIUsageError.networkError(
                NSError(domain: "APIUsageFetcher", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            )
        }

        switch http.statusCode {
        case 200:
            return try JSONDecoder().decode(APIUsageResponse.self, from: data)
        case 401:
            throw APIUsageError.unauthorized
        case 429:
            throw APIUsageError.rateLimited
        default:
            throw APIUsageError.httpError(http.statusCode)
        }
    }
}
