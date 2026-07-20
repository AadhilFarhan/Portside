import SwiftUI
import PortsideCore

struct DashboardView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""

    private var devServers: [DevServer] { filtered(model.devServers) }
    private var otherServers: [DevServer] { filtered(model.otherServers) }

    private func filtered(_ servers: [DevServer]) -> [DevServer] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return servers }
        return servers.filter {
            $0.displayName.lowercased().contains(q)
                || String($0.port).contains(q)
                || $0.framework.displayName.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !model.hasScannedOnce {
                Spacer()
                ProgressView().controlSize(.large)
                Spacer()
            } else if devServers.isEmpty && otherServers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6, pinnedViews: .sectionHeaders) {
                        if !devServers.isEmpty {
                            section("Dev servers", servers: devServers)
                        }
                        if !otherServers.isEmpty {
                            section("System & apps", servers: otherServers)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 620, minHeight: 400)
        .background(.background)
    }

    private var header: some View {
        HStack(spacing: 12) {
            appMark
            VStack(alignment: .leading, spacing: 1) {
                Text("Portside")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                TextField("Filter by name, port, framework", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 190)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.06)))

            if let ip = model.lanAddress {
                Label(ip, systemImage: "wifi")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .help("Your Mac on the local network — QR codes point here")
            } else {
                Label("offline", systemImage: "wifi.slash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 30)
        .padding(.bottom, 12)
    }

    private var appMark: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0x0B2A4A), Color(hex: 0x1E6FD9)],
                    startPoint: .bottom, endPoint: .top
                )
            )
            .frame(width: 34, height: 34)
            .overlay(
                VStack(alignment: .leading, spacing: 3) {
                    bar(14); bar(10); bar(7)
                }
            )
    }

    private func bar(_ width: CGFloat) -> some View {
        Capsule().fill(.white).frame(width: width, height: 3)
    }

    private var subtitle: String {
        let dev = model.devServers.count
        let sys = model.otherServers.count
        var text = "\(dev) dev server\(dev == 1 ? "" : "s")"
        if sys > 0 { text += " · \(sys) system" }
        return text
    }

    private func section(_ title: String, servers: [DevServer]) -> some View {
        Section {
            ForEach(servers) { server in
                DashboardRow(server: server)
            }
        } header: {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .background(.background)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: query.isEmpty ? "moon.zzz.fill" : "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text(query.isEmpty ? "No dev servers running" : "Nothing matches “\(query)”")
                .font(.system(size: 14, weight: .semibold))
            if query.isEmpty {
                Text("Start one — npm run dev, rails s, anything — and it shows up here.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DashboardRow: View {
    @Environment(AppModel.self) private var model
    let server: DevServer

    @State private var hovering = false
    @State private var showingQR = false

    private var isKilling: Bool { model.killingPIDs.contains(server.pid) }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(server.framework.accent.gradient)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(server.monogram)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(server.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    bindBadge
                    if model.shares[server.port] != nil {
                        Label("sharing", systemImage: "wifi")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }
                HStack(spacing: 0) {
                    Text(server.subtitleText)
                    if let cwd = server.workingDirectory {
                        Text("  ·  ")
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: cwd)])
                        } label: {
                            Text(abbreviate(cwd))
                                .underline(hovering)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(String(server.port))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(0.07)))

            if isKilling {
                ProgressView().controlSize(.small).frame(width: 88)
            } else {
                HStack(spacing: 2) {
                    rowAction("safari", help: "Open in browser") {
                        NSWorkspace.shared.open(server.localURL)
                    }
                    rowAction("doc.on.doc", help: "Copy localhost URL") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(server.localURL.absoluteString, forType: .string)
                    }
                    rowAction("qrcode", help: "Open on your phone") {
                        showingQR.toggle()
                    }
                    .disabled(model.lanAddress == nil)
                    .popover(isPresented: $showingQR, arrowEdge: .bottom) {
                        QRPanel(server: server, dismiss: { showingQR = false })
                            .frame(width: 240)
                            .padding(.top, 6)
                    }
                    rowAction("xmark", help: "Stop this server", role: .destructive) {
                        model.kill(server)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(hovering ? Color.primary.opacity(0.05) : Color.primary.opacity(0.025))
        )
        .onHover { hovering = $0 }
        .opacity(isKilling ? 0.5 : 1)
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    @ViewBuilder
    private var bindBadge: some View {
        switch server.scope {
        case .loopback:
            badge("local only", color: .secondary)
        case .allInterfaces:
            badge("on network", color: .green)
        case .specific:
            badge("bound", color: .orange)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
    }

    private func abbreviate(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    private func rowAction(
        _ symbol: String, help: String, role: ButtonRole? = nil, perform: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: perform) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 24)
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(HoverButtonStyle(destructive: role == .destructive))
        .help(help)
    }
}
