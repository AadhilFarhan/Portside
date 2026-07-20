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

        // Drop relays whose target vanished (server was stopped elsewhere).
        let livePorts = Set(servers.map(\.port))
        for (port, relay) in relays where !livePorts.contains(port) {
            relay.stop()
            relays[port] = nil
            shares[port] = nil
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
    /// to all interfaces are reachable directly; loopback-bound ones get a
    /// relay. `ShareProxy`'s init can block briefly waiting for its listener,
    /// so — like `PortScanner.scan()` — it's built off the main actor.
    func startSharing(_ server: DevServer) async -> ActiveShare? {
        if let existing = shares[server.port] { return existing }
        guard let ip = lanAddress else { return nil }

        if server.scope == .allInterfaces {
            let share = ActiveShare(url: URL(string: "http://\(ip):\(server.port)")!, isRelayed: false)
            shares[server.port] = share
            return share
        }

        let targetPort = server.port
        let relay = await Task.detached(priority: .utility) {
            try? ShareProxy(targetPort: targetPort)
        }.value

        // Another call could have started (or stopped) a share for this port
        // while we were suspended constructing the relay above.
        if let existing = shares[server.port] {
            relay?.stop()
            return existing
        }
        guard let relay, relay.listenPort > 0 else { return nil }

        relays[server.port] = relay
        let share = ActiveShare(url: URL(string: "http://\(ip):\(relay.listenPort)")!, isRelayed: true)
        shares[server.port] = share
        return share
    }

    func stopSharing(port: Int) {
        relays[port]?.stop()
        relays[port] = nil
        shares[port] = nil
    }
}
