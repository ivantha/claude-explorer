import Foundation

final class SessionAnalyzer {
    private let windowDuration: TimeInterval = 5 * 60 * 60 // 5 hours

    func analyze(entries: [UsageEntry]) -> [SessionBlock] {
        guard !entries.isEmpty else { return [] }

        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        var blocks: [SessionBlock] = []
        var currentStart = sorted[0].timestamp
        var currentEnd = currentStart.addingTimeInterval(windowDuration)
        var currentEntries: [UsageEntry] = []

        for entry in sorted {
            if entry.timestamp > currentEnd {
                // Save current block
                if !currentEntries.isEmpty {
                    blocks.append(SessionBlock(
                        startTime: currentStart,
                        endTime: currentEnd,
                        entries: currentEntries
                    ))
                }
                // Start new block
                currentStart = entry.timestamp
                currentEnd = currentStart.addingTimeInterval(windowDuration)
                currentEntries = [entry]
            } else {
                currentEntries.append(entry)
            }
        }

        // Don't forget the last block
        if !currentEntries.isEmpty {
            blocks.append(SessionBlock(
                startTime: currentStart,
                endTime: currentEnd,
                entries: currentEntries
            ))
        }

        return blocks
    }

    func activeBlock(from blocks: [SessionBlock]) -> SessionBlock? {
        let now = Date()
        return blocks.last { $0.endTime > now }
    }
}
