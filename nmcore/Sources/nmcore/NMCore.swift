import Foundation

public enum NMCore {
    public static var nmPath: String = "/usr/bin/nm"

    public static func scanFile(path: String) -> String {
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

    public static func scanFile(url: URL) -> String {
        scanFile(path: url.path)
    }

    public static func grep(_ query: String, in text: String) -> [Int] {
        guard !query.isEmpty, !text.isEmpty else { return [] }

        let nsText = text as NSString
        var results: [Int] = []
        var searchRange = NSRange(location: 0, length: nsText.length)

        while searchRange.length > 0 {
            let found = nsText.range(of: query, options: .literal, range: searchRange)
            if found.location == NSNotFound { break }
            results.append(found.location)

            let nextLocation = found.location + 1
            if nextLocation >= nsText.length { break }
            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }

        return results
    }

    public static func multiGrep(_ queries: [String], in text: String) -> [String: [Int]] {
        guard !queries.isEmpty, !text.isEmpty else { return [:] }

        var results: [String: [Int]] = [:]
        for query in queries {
            results[query] = grep(query, in: text)
        }
        return results
    }
}
