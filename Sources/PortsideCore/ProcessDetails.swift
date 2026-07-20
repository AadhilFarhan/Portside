import Foundation

public struct ProcessDetails: Sendable, Equatable {
    public let pid: Int32
    public let cpuPercent: Double
    public let residentBytes: Int64
    public let elapsed: TimeInterval
    public let arguments: String

    public init(pid: Int32, cpuPercent: Double, residentBytes: Int64, elapsed: TimeInterval, arguments: String) {
        self.pid = pid
        self.cpuPercent = cpuPercent
        self.residentBytes = residentBytes
        self.elapsed = elapsed
        self.arguments = arguments
    }

    /// First token of args — wrong for paths containing spaces, so scanners
    /// should prefer the `ps -o comm=` value where available.
    public var executable: String {
        String(arguments.split(separator: " ", maxSplits: 1)[0])
    }
}

/// Parses `ps -o pid=,comm= -p ...`: pid, then the executable path, which may
/// itself contain spaces — it is the only other column, so everything after
/// the pid belongs to it.
public enum PsCommParser {
    public static func parse(_ output: String) -> [Int32: String] {
        var result: [Int32: String] = [:]
        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let space = trimmed.firstIndex(of: " "),
                  let pid = Int32(trimmed[..<space]) else { continue }
            let comm = trimmed[trimmed.index(after: space)...].trimmingCharacters(in: .whitespaces)
            if !comm.isEmpty { result[pid] = comm }
        }
        return result
    }
}

/// Parses `ps -o pid=,pcpu=,rss=,etime=,args= -p ...` output.
public enum PsParser {

    public static func parse(_ output: String) -> [Int32: ProcessDetails] {
        var result: [Int32: ProcessDetails] = [:]
        for line in output.split(separator: "\n") {
            let fields = line.split(separator: " ", omittingEmptySubsequences: true)
            guard fields.count >= 5,
                  let pid = Int32(fields[0]),
                  let cpu = Double(fields[1]),
                  let rssKB = Int64(fields[2])
            else { continue }
            let elapsed = parseElapsed(String(fields[3])) ?? 0
            let args = fields[4...].joined(separator: " ")
            result[pid] = ProcessDetails(
                pid: pid, cpuPercent: cpu, residentBytes: rssKB * 1024,
                elapsed: elapsed, arguments: args
            )
        }
        return result
    }

    /// ps etime formats: `MM:SS`, `HH:MM:SS`, `D-HH:MM:SS`.
    static func parseElapsed(_ etime: String) -> TimeInterval? {
        var days = 0.0
        var clock = etime
        if let dash = etime.firstIndex(of: "-") {
            guard let d = Double(etime[..<dash]) else { return nil }
            days = d
            clock = String(etime[etime.index(after: dash)...])
        }
        let parts = clock.split(separator: ":").map { Double($0) }
        guard parts.allSatisfy({ $0 != nil }), (2...3).contains(parts.count) else { return nil }
        let values = parts.compactMap(\.self)
        var seconds = 0.0
        for value in values { seconds = seconds * 60 + value }
        return days * 86400 + seconds
    }
}
