import Foundation

enum Shell {
    static func run(_ path: String, _ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return ""
        }
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}

public enum PortScanner {

    /// Full scan: listening TCP sockets joined with per-process stats and
    /// project detection. Blocking (three subprocess calls); call off-main.
    public static func scan() -> [DevServer] {
        let lsofOut = Shell.run("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN", "-Fpcn"])
        let sockets = LsofParser.parse(lsofOut)
        guard !sockets.isEmpty else { return [] }

        let pids = Set(sockets.map(\.pid))
        let pidList = pids.map(String.init).joined(separator: ",")

        let psOut = Shell.run("/bin/ps", ["-o", "pid=,pcpu=,rss=,etime=,args=", "-p", pidList])
        let details = PsParser.parse(psOut)

        let commOut = Shell.run("/bin/ps", ["-o", "pid=,comm=", "-p", pidList])
        let comms = PsCommParser.parse(commOut)

        let cwdOut = Shell.run("/usr/sbin/lsof", ["-a", "-p", pidList, "-d", "cwd", "-Fpn"])
        let cwds = parseCwds(cwdOut)

        return sockets.map { socket in
            let detail = details[socket.pid]
            let arguments = detail?.arguments ?? socket.command
            let executable = comms[socket.pid] ?? detail?.executable ?? socket.command
            let framework = Classifier.framework(arguments: arguments)
            let cwd = cwds[socket.pid]
            let project = cwd.flatMap { ProjectNamer.projectName(cwd: $0) }
            return DevServer(
                pid: socket.pid,
                port: socket.port,
                scope: socket.scope,
                executable: executable,
                arguments: arguments,
                projectName: project,
                workingDirectory: cwd,
                framework: framework,
                kind: Classifier.kind(executable: executable, framework: framework),
                cpuPercent: detail?.cpuPercent ?? 0,
                residentBytes: detail?.residentBytes ?? 0,
                elapsed: detail?.elapsed ?? 0
            )
        }
        .sorted { ($0.kind == .dev ? 0 : 1, $0.port, $0.pid) < ($1.kind == .dev ? 0 : 1, $1.port, $1.pid) }
    }

    /// Parses `lsof -a -p ... -d cwd -Fpn`: `p<pid>` then `n<path>` pairs.
    static func parseCwds(_ output: String) -> [Int32: String] {
        var result: [Int32: String] = [:]
        var pid: Int32 = -1
        for line in output.split(separator: "\n") {
            guard let tag = line.first else { continue }
            let value = String(line.dropFirst())
            if tag == "p" { pid = Int32(value) ?? -1 }
            if tag == "n", pid > 0 { result[pid] = value }
        }
        return result
    }
}

public enum ProcessKiller {

    /// SIGTERM, grace period, then SIGKILL. Returns true when the process is gone.
    public static func kill(pid: Int32, gracePeriod: TimeInterval = 3.0) async -> Bool {
        Darwin.kill(pid, SIGTERM)
        let deadline = Date().addingTimeInterval(gracePeriod)
        while Date() < deadline {
            try? await Task.sleep(for: .milliseconds(150))
            if !isAlive(pid) { return true }
        }
        Darwin.kill(pid, SIGKILL)
        try? await Task.sleep(for: .milliseconds(300))
        return !isAlive(pid)
    }

    public static func isAlive(_ pid: Int32) -> Bool {
        Darwin.kill(pid, 0) == 0 || errno == EPERM
    }
}
