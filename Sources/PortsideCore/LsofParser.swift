import Foundation

/// Parses `lsof -nP -iTCP -sTCP:LISTEN -Fpcn` machine-format output.
///
/// The format is line-oriented: `p<pid>` starts a process block, `c<command>`
/// names it, and each `n<addr>` line is one listening socket, e.g. `n*:3000`,
/// `n127.0.0.1:8080`, `n[::1]:5432`.
public enum LsofParser {

    public static func parse(_ output: String) -> [ListeningSocket] {
        var sockets: [ListeningSocket] = []
        var seen = Set<String>()
        var pid: Int32 = -1
        var command = ""

        for line in output.split(separator: "\n") {
            guard let tag = line.first else { continue }
            let value = String(line.dropFirst())
            switch tag {
            case "p":
                pid = Int32(value) ?? -1
                command = ""
            case "c":
                command = value
            case "n":
                guard pid > 0, let (port, scope) = parseAddress(value) else { continue }
                let key = "\(pid):\(port)"
                if seen.insert(key).inserted {
                    sockets.append(ListeningSocket(pid: pid, command: command, port: port, scope: scope))
                }
            default:
                continue
            }
        }
        return sockets
    }

    static func parseAddress(_ address: String) -> (port: Int, scope: BindScope)? {
        guard let colon = address.lastIndex(of: ":"),
              let port = Int(address[address.index(after: colon)...]),
              port > 0
        else { return nil }

        let host = String(address[..<colon])
        let scope: BindScope
        switch host {
        case "*":
            scope = .allInterfaces
        case "127.0.0.1", "[::1]", "localhost":
            scope = .loopback
        default:
            scope = host.hasPrefix("127.") ? .loopback : .specific
        }
        return (port, scope)
    }
}
