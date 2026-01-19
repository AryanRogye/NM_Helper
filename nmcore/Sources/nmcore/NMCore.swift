import Foundation

public enum NMFlags {
    case external_symbols
    case hide_undefined_symbols
    case sort_by_address
    case no_sorting
    case reverse_sort
    case just_symbol_names
    case include_debug_symbols
    case only_undefined_symbols
    
    public var flag: String {
        switch self {
            
        case .external_symbols:
            "-g"
        case .hide_undefined_symbols:
            "-U"
            
        case .sort_by_address:
            "-n"
        case .no_sorting:
            "-p"
            
        case .reverse_sort:
            "-r"
            
        case .just_symbol_names:
            "-j"
            
        case .include_debug_symbols:
            "-a"
        case .only_undefined_symbols:
            "-u"
        }
    }
}

public final class NMCore: Sendable {
    
    public let nmPath: String
    

    public init(nmPath: String = "/usr/bin/nm") {
        self.nmPath = nmPath
    }

    public func scanFile(path: String, options: [NMFlags] = []) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: nmPath)
        
        let arguments : [String] = options.map(\.flag) + [path]
        process.arguments = arguments
        
        process.standardOutput = pipe
        process.standardError = pipe
        

        let result: String = try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try process.run()

            // Read while the process runs so stdout/stderr can't block on a full pipe.
            let data = try await pipe.fileHandleForReading.readToEnd() ?? Data()
            process.waitUntilExit()

            try Task.checkCancellation()

            let output = String(decoding: data, as: UTF8.self)

            if process.terminationStatus != 0 {
                throw NSError(
                    domain: "NMCore",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "nm \(path) failed: exit \(process.terminationStatus)\n\(output)"]
                )
            }

            return output
        } onCancel: {
            process.interrupt()
            process.terminate()
            try? pipe.fileHandleForReading.close()
        }
        
        return result
    }
    
    public func scanFile(url: URL, options: [NMFlags] = []) async throws -> String {
        try await scanFile(path: url.path, options: options)
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
