import Foundation
import Darwin

public enum NetworkInfo {

    /// The Mac's IPv4 address on the local network, preferring Wi-Fi/Ethernet
    /// (`en*`) interfaces. Nil when not connected to any network.
    public static func lanAddress() -> String? {
        var addrList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrList) == 0, let first = addrList else { return nil }
        defer { freeifaddrs(addrList) }

        var candidates: [(name: String, address: String)] = []
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            defer { cursor = ifa.pointee.ifa_next }
            guard let sa = ifa.pointee.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET) else { continue }
            let flags = Int32(ifa.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            let name = String(cString: ifa.pointee.ifa_name)
            guard name.hasPrefix("en") || name.hasPrefix("bridge") else { continue }
            var host = [UInt8](repeating: 0, count: Int(NI_MAXHOST))
            let ok = host.withUnsafeMutableBufferPointer { buf in
                buf.baseAddress!.withMemoryRebound(to: CChar.self, capacity: buf.count) { p in
                    getnameinfo(sa, socklen_t(sa.pointee.sa_len), p, socklen_t(buf.count),
                                nil, 0, NI_NUMERICHOST) == 0
                }
            }
            if ok {
                let bytes = host.prefix(while: { $0 != 0 })
                candidates.append((name, String(decoding: bytes, as: UTF8.self)))
            }
        }
        return candidates.min { $0.name < $1.name }?.address
    }
}
