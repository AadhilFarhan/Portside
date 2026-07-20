import SwiftUI
import ServiceManagement
import PortsideCore

struct MenuContent: View {
    @Environment(AppModel.self) private var model
    @State private var showingOthers = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 10)
            content
        }
        .frame(width: 340)
        .task { await model.refresh() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Portside")
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Spacer()
            if let ip = model.lanAddress {
                Label(ip, systemImage: "wifi")
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .help("Your Mac on the local network")
            } else {
                Label("offline", systemImage: "wifi.slash")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            Button {
                WindowManager.shared.showDashboard(model: model)
            } label: {
                Image(systemName: "macwindow")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22, height: 20)
                    .contentShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(HoverButtonStyle())
            .help("Open the Portside dashboard")
            settingsMenu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var settingsMenu: some View {
        Menu {
            Button("Open Dashboard") {
                WindowManager.shared.showDashboard(model: model)
            }
            Button(launchAtLoginEnabled ? "Disable Launch at Login" : "Launch at Login") {
                toggleLaunchAtLogin()
            }
            Divider()
            Button("Quit Portside") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    @ViewBuilder
    private var content: some View {
        if !model.hasScannedOnce {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        } else if model.devServers.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(model.devServers) { server in
                        ServerRow(server: server)
                    }
                }
                .padding(.vertical, 5)
            }
            .frame(maxHeight: 420)
        }

        if !model.otherServers.isEmpty {
            Divider().padding(.horizontal, 10)
            othersSection
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 26))
                .foregroundStyle(.tertiary)
            Text("No dev servers running")
                .font(.system(size: 12.5, weight: .semibold))
            Text("Start one — npm run dev, rails s, anything —\nand it shows up here.")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    private var othersSection: some View {
        VStack(spacing: 1) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    showingOthers.toggle()
                }
            } label: {
                HStack {
                    Text("System & apps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(model.otherServers.count))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showingOthers ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showingOthers {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(model.otherServers) { server in
                            ServerRow(server: server)
                        }
                    }
                }
                .frame(maxHeight: 180)
                .padding(.bottom, 5)
                .transition(.opacity)
            }
        }
    }

    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func toggleLaunchAtLogin() {
        do {
            if launchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }
    }
}
