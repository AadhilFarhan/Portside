import Foundation
import Observation
import PortsideCore

struct ActiveShare: Equatable {
    let url: URL
    let isRelayed: Bool
}

@MainActor
@Observable
final class AppModel {

    private(set) var devServers: [DevServer] = []
    private(set) var otherServers: [DevServer] = []
    private(set) var lanAddress: String?
    private(set) var killingPIDs: Set<Int32> = []
    private(set) var shares: [Int: ActiveShare] = [:]
    private(set) var hasScannedOnce = false

    private var relays: [Int: ShareProxy] = [:]
    private var sharedPIDs: [Int: Int32] = [:]
    private var pollTask: Task<Void, Never>?

    init() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func refresh() async {
        let servers = await Task.detached(priority: .utility) { PortScanner.scan() }.value
        lanAddress = NetworkInfo.lanAddress()
        devServers = servers.filter { $0.kind == .dev }
        otherServers = servers.filter { $0.kind == .other }
        hasScannedOnce = true

        // Drop shares whose process vanished, or whose port now belongs to a
        // different process than the one the user actually chose to share —
        // a share must never silently start exposing a process nobody opted
        // into just because it happened to reuse a freed port.
        let livePIDsByPort = Dictionary(servers.map { ($0.port, $0.pid) }, uniquingKeysWith: { first, _ in first })
        for port in Array(sharedPIDs.keys) where livePIDsByPort[port] != sharedPIDs[port] {
            relays[port]?.stop()
            relays[port] = nil
            shares[port] = nil
            sharedPIDs[port] = nil
        }
    }

    func kill(_ server: DevServer) {
        killingPIDs.insert(server.pid)
        Task {
            _ = await ProcessKiller.kill(pid: server.pid)
            killingPIDs.remove(server.pid)
            stopSharing(port: server.port)
            await refresh()
        }
    }

    /// Returns a URL reachable from other devices on the Wi-Fi. Servers bound
    /// to all interfaces are reachable directly; loopback-bound ones get a relay.
    func startSharing(_ server: DevServer) -> ActiveShare? {
        if let existing = shares[server.port] { return existing }
        guard let ip = lanAddress else { return nil }

        if server.scope == .allInterfaces {
            let share = ActiveShare(url: URL(string: "http://\(ip):\(server.port)")!, isRelayed: false)
            shares[server.port] = share
            sharedPIDs[server.port] = server.pid
            return share
        }
        guard let relay = try? ShareProxy(targetPort: server.port), relay.listenPort > 0 else {
            return nil
        }
        relays[server.port] = relay
        let share = ActiveShare(url: URL(string: "http://\(ip):\(relay.listenPort)")!, isRelayed: true)
        shares[server.port] = share
        sharedPIDs[server.port] = server.pid
        return share
    }

    func stopSharing(port: Int) {
        relays[port]?.stop()
        relays[port] = nil
        shares[port] = nil
        sharedPIDs[port] = nil
    }
}
