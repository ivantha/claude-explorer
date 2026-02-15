import Foundation

final class JSONLReader: Sendable {
    func readEntries(since cutoff: Date) async -> [UsageEntry] {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
        let projectsURL = claudeDir.appendingPathComponent("projects")
        guard FileManager.default.fileExists(atPath: projectsURL.path) else { return [] }

        let jsonlFiles = findJSONLFiles(in: projectsURL, modifiedSince: cutoff)
        var allEntries: [String: UsageEntry] = [:] // keyed by dedup ID

        await withTaskGroup(of: [UsageEntry].self) { group in
            for fileURL in jsonlFiles {
                group.addTask {
                    Self.parseFile(at: fileURL)
                }
            }
            for await fileEntries in group {
                for entry in fileEntries {
                    // Keep last occurrence for each ID (streaming sends incremental updates)
                    allEntries[entry.id] = entry
                }
            }
        }

        return Array(allEntries.values)
    }

    private func findJSONLFiles(in directory: URL, modifiedSince cutoff: Date) -> [URL] {
        var files: [URL] = []
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }

            do {
                let values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey])
                guard values.isRegularFile == true else { continue }
                if let modDate = values.contentModificationDate, modDate >= cutoff {
                    files.append(fileURL)
                }
            } catch {
                continue
            }
        }

        return files
    }

    private static func parseFile(at url: URL) -> [UsageEntry] {
        var entries: [UsageEntry] = []

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return [] }

        for line in content.components(separatedBy: .newlines) {
            guard !line.isEmpty else { continue }
            if let entry = parseLine(line) {
                entries.append(entry)
            }
        }

        return entries
    }

    private static func parseLine(_ line: String) -> UsageEntry? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let type = json["type"] as? String ?? ""

        switch type {
        case "assistant":
            return parseAssistantEntry(json: json)
        case "progress":
            return parseProgressEntry(json: json)
        default:
            return nil
        }
    }

    private static func parseAssistantEntry(json: [String: Any]) -> UsageEntry? {
        guard let message = json["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any] else {
            return nil
        }

        let model = message["model"] as? String ?? "unknown"
        let messageId = message["id"] as? String ?? UUID().uuidString
        let requestId = json["requestId"] as? String ?? ""
        let dedupId = "\(messageId):\(requestId)"

        guard let timestamp = parseTimestamp(json["timestamp"]) else { return nil }

        let inputTokens = usage["input_tokens"] as? Int ?? 0
        let outputTokens = usage["output_tokens"] as? Int ?? 0
        let cacheCreation = usage["cache_creation_input_tokens"] as? Int ?? 0
        let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0

        // Skip entries with no meaningful token counts
        guard inputTokens > 0 || outputTokens > 0 || cacheCreation > 0 || cacheRead > 0 else {
            return nil
        }

        return UsageEntry(
            id: dedupId,
            timestamp: timestamp,
            model: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheCreationTokens: cacheCreation,
            cacheReadTokens: cacheRead
        )
    }

    private static func parseProgressEntry(json: [String: Any]) -> UsageEntry? {
        guard let dataObj = json["data"] as? [String: Any],
              let dataMessage = dataObj["message"] as? [String: Any],
              let dataMessageType = dataMessage["type"] as? String,
              dataMessageType == "assistant",
              let innerMessage = dataMessage["message"] as? [String: Any],
              let usage = innerMessage["usage"] as? [String: Any] else {
            return nil
        }

        let model = innerMessage["model"] as? String ?? "unknown"
        let messageId = innerMessage["id"] as? String ?? UUID().uuidString
        let toolUseID = json["toolUseID"] as? String ?? ""
        let dedupId = "\(messageId):\(toolUseID)"

        let timestamp = parseTimestamp(dataMessage["timestamp"]) ?? parseTimestamp(json["timestamp"])
        guard let ts = timestamp else { return nil }

        let inputTokens = usage["input_tokens"] as? Int ?? 0
        let outputTokens = usage["output_tokens"] as? Int ?? 0
        let cacheCreation = usage["cache_creation_input_tokens"] as? Int ?? 0
        let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0

        guard inputTokens > 0 || outputTokens > 0 || cacheCreation > 0 || cacheRead > 0 else {
            return nil
        }

        return UsageEntry(
            id: dedupId,
            timestamp: ts,
            model: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheCreationTokens: cacheCreation,
            cacheReadTokens: cacheRead
        )
    }

    private static func parseTimestamp(_ value: Any?) -> Date? {
        guard let str = value as? String else { return nil }
        return isoFormatter.date(from: str)
    }

    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
