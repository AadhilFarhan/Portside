import SwiftUI
import PortsideCore

struct ServerRow: View {
    @Environment(AppModel.self) private var model
    let server: DevServer

    @State private var hovering = false
    @State private var showingQR = false

    private var isKilling: Bool { model.killingPIDs.contains(server.pid) }
    private var share: ActiveShare? { model.shares[server.port] }

    var body: some View {
        VStack(spacing: 0) {
            row
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hovering ? Color.primary.opacity(0.06) : .clear)
                )
                .onHover { hovering = $0 }
                .onTapGesture { NSWorkspace.shared.open(server.localURL) }

            if showingQR {
                QRPanel(server: server, dismiss: { withAnimation(panelSpring) { showingQR = false } })
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(isKilling ? 0.45 : 1)
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    private var panelSpring: Animation { .spring(response: 0.32, dampingFraction: 0.86) }

    private var row: some View {
        HStack(spacing: 10) {
            glyph
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(server.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    if share != nil {
                        Image(systemName: "wifi")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.green)
                            .help("Being shared on your network")
                    }
                }
                Text(server.subtitleText)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)

            if isKilling {
                ProgressView().controlSize(.small)
            } else if hovering {
                actions
            } else {
                Text(String(server.port))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.07)))
            }
        }
    }

    private var glyph: some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(server.framework.accent.gradient)
            .frame(width: 28, height: 28)
            .overlay(
                Text(server.monogram)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
    }

    private var actions: some View {
        HStack(spacing: 2) {
            action("doc.on.doc", help: "Copy localhost URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(server.localURL.absoluteString, forType: .string)
            }
            action("qrcode", help: "Open on your phone") {
                withAnimation(panelSpring) { showingQR.toggle() }
            }
            .disabled(model.lanAddress == nil)
            action("xmark", help: "Stop this server", role: .destructive) {
                model.kill(server)
            }
        }
    }

    private func action(
        _ symbol: String, help: String, role: ButtonRole? = nil, perform: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: perform) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 22)
                .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(HoverButtonStyle(destructive: role == .destructive))
        .help(help)
    }
}

struct HoverButtonStyle: ButtonStyle {
    var destructive = false
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(hovering ? (destructive ? Color.red : .primary) : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hovering ? Color.primary.opacity(0.08) : .clear)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
