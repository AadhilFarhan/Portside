import SwiftUI
import PortsideCore

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension Framework {

    var accent: Color {
        switch self {
        case .vite: Color(hex: 0x646CFF)
        case .next: Color(hex: 0x111111)
        case .nuxt: Color(hex: 0x00DC82)
        case .astro: Color(hex: 0xFF5D01)
        case .remix: Color(hex: 0x3992FF)
        case .webpack: Color(hex: 0x1C78C0)
        case .cra: Color(hex: 0x149ECA)
        case .node: Color(hex: 0x5FA04E)
        case .bun: Color(hex: 0xC7A87B)
        case .deno: Color(hex: 0x70FFAF)
        case .django: Color(hex: 0x44B78B)
        case .flask: Color(hex: 0x8A8D93)
        case .fastapi: Color(hex: 0x009688)
        case .python: Color(hex: 0x3776AB)
        case .rails: Color(hex: 0xCC0000)
        case .ruby: Color(hex: 0xCC342D)
        case .laravel: Color(hex: 0xFF2D20)
        case .php: Color(hex: 0x777BB4)
        case .go: Color(hex: 0x00ADD8)
        case .rust: Color(hex: 0xB7410E)
        case .dotnet: Color(hex: 0x512BD4)
        case .java: Color(hex: 0xE76F00)
        case .postgres: Color(hex: 0x336791)
        case .mysql: Color(hex: 0x00758F)
        case .redis: Color(hex: 0xDC382D)
        case .mongo: Color(hex: 0x47A248)
        case .docker: Color(hex: 0x2496ED)
        case .caddy: Color(hex: 0x22B638)
        case .nginx: Color(hex: 0x009639)
        case .unknown: Color(hex: 0x8A8D93)
        }
    }
}

extension DevServer {

    var monogram: String {
        let name = displayName
        guard let first = name.first(where: { $0.isLetter || $0.isNumber }) else { return "?" }
        return String(first).uppercased()
    }

    var uptimeText: String {
        let seconds = Int(elapsed)
        switch seconds {
        case ..<60: return "\(seconds)s"
        case ..<3600: return "\(seconds / 60)m"
        case ..<86400: return "\(seconds / 3600)h \(seconds % 3600 / 60)m"
        default: return "\(seconds / 86400)d"
        }
    }

    var memoryText: String {
        ByteCountFormatter.string(fromByteCount: residentBytes, countStyle: .memory)
    }

    var subtitleText: String {
        var parts: [String] = []
        if framework != .unknown, framework.displayName != displayName {
            parts.append(framework.displayName)
        } else if framework == .unknown {
            parts.append((executable as NSString).lastPathComponent)
        }
        parts.append(uptimeText)
        parts.append(memoryText)
        return parts.joined(separator: " · ")
    }
}
