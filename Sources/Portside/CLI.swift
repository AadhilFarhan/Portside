import Foundation
import PortsideCore

/// Headless modes for scripting and for verifying the engine without the UI:
/// `Portside --scan` prints what the menu would show; `Portside --share 3000`
/// relays that port to the LAN and prints the URL a phone would open.
enum CLI {

    static func runIfRequested() -> Bool {
        setlinebuf(stdout)
        let args = CommandLine.arguments
        if args.contains("--scan") {
            scan()
            return true
        }
        if let index = args.firstIndex(of: "--share"), args.count > index + 1,
           let port = Int(args[index + 1]) {
            share(port: port)
            return true
        }
        return false
    }

    private static func scan() {
        let servers = PortScanner.scan()
        if servers.isEmpty {
            print("No listening TCP ports found.")
            return
        }
        print("KIND  PORT   NAME                 FRAMEWORK    PID     BIND        CPU%   UPTIME")
        for server in servers {
            let kind = server.kind == .dev ? "dev " : "sys "
            let name = server.displayName.prefix(20)
            let fw = server.framework == .unknown ? "-" : server.framework.displayName
            let line = String(
                format: "%@  %-5d  %-20@ %-12@ %-7d %-11@ %-6.1f %.0fs",
                kind, server.port, name as CVarArg, fw as CVarArg, server.pid,
                server.scope.rawValue as CVarArg, server.cpuPercent, server.elapsed
            )
            print(line)
        }
    }

    private static func share(port: Int) {
        guard let ip = NetworkInfo.lanAddress() else {
            print("error: no LAN address (not connected to a network)")
            exit(1)
        }
        do {
            let proxy = try ShareProxy(targetPort: port)
            guard proxy.listenPort > 0 else {
                print("error: relay failed to start")
                exit(1)
            }
            print("Relaying 127.0.0.1:\(port) -> http://\(ip):\(proxy.listenPort)  (Ctrl-C to stop)")
            dispatchMain()
        } catch {
            print("error: \(error)")
            exit(1)
        }
    }
}
