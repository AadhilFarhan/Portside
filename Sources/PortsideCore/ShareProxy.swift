import Foundation
import Network

/// A TCP relay that listens on every interface and pipes bytes to a target
/// port on loopback. This is what lets a phone on the same Wi-Fi reach a dev
/// server that bound only to 127.0.0.1 — the relay is reachable from the LAN,
/// the dev server never has to change how it binds. Being a raw byte pipe, it
/// carries HTTP, WebSockets (hot reload), and anything else over TCP.
public final class ShareProxy: @unchecked Sendable {

    public let targetPort: Int
    private let listener: NWListener
    private let queue = DispatchQueue(label: "portside.proxy")
    private let lock = NSLock()
    private var connections: [ObjectIdentifier: (NWConnection, NWConnection)] = [:]

    public var listenPort: Int {
        Int(listener.port?.rawValue ?? 0)
    }

    /// Starts immediately on an OS-assigned port.
    public init(targetPort: Int) throws {
        self.targetPort = targetPort
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        listener = try NWListener(using: params, on: .any)
        listener.newConnectionHandler = { [weak self] inbound in
            self?.relay(inbound)
        }

        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state { ready.signal() }
            if case .failed = state { ready.signal() }
        }
        listener.start(queue: queue)
        _ = ready.wait(timeout: .now() + 2)
        listener.stateUpdateHandler = nil
    }

    public func stop() {
        listener.cancel()
        lock.lock()
        let open = connections.values
        connections.removeAll()
        lock.unlock()
        for (inbound, outbound) in open {
            inbound.cancel()
            outbound.cancel()
        }
    }

    private func relay(_ inbound: NWConnection) {
        let outbound = NWConnection(
            host: "127.0.0.1",
            port: NWEndpoint.Port(rawValue: UInt16(targetPort))!,
            using: .tcp
        )
        lock.lock()
        connections[ObjectIdentifier(inbound)] = (inbound, outbound)
        lock.unlock()

        inbound.start(queue: queue)
        outbound.start(queue: queue)
        pump(from: inbound, to: outbound)
        pump(from: outbound, to: inbound)
    }

    private func pump(from source: NWConnection, to sink: NWConnection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 128 * 1024) {
            [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                sink.send(content: data, completion: .contentProcessed { _ in
                    self.pump(from: source, to: sink)
                })
            } else if isComplete || error != nil {
                self.close(source, sink)
            } else {
                self.pump(from: source, to: sink)
            }
        }
    }

    private func close(_ a: NWConnection, _ b: NWConnection) {
        lock.lock()
        connections.removeValue(forKey: ObjectIdentifier(a))
        connections.removeValue(forKey: ObjectIdentifier(b))
        lock.unlock()
        a.cancel()
        b.cancel()
    }
}
