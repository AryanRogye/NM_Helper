import Foundation

public final class NMCore: Sendable {
    public let nmPath: String

    public init(nmPath: String = "/usr/bin/nm") {
        self.nmPath = nmPath
    }

    public func scanFile(path: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: nmPath)
        process.arguments = [path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return "nm \(path) failed: \(error.localizedDescription)"
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(decoding: data, as: UTF8.self)
        if process.terminationStatus != 0 {
            return "nm \(path) failed: exit \(process.terminationStatus)\n\(output)"
        }

        return output
    }

    public func scanFile(url: URL) -> String {
        scanFile(path: url.path)
    }

    public func grep(_ query: String, in text: String) -> [Int] {
        guard !query.isEmpty, !text.isEmpty else { return [] }
        return BoyerMoore.search(pattern: query, text: text)
    }

    public func multiGrep(_ queries: [String], in text: String) -> [String: [Int]] {
        guard !queries.isEmpty, !text.isEmpty else { return [:] }

        var results: [String: [Int]] = [:]
        for query in queries {
            results[query] = grep(query, in: text)
        }
        return results
    }
}
