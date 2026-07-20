import SwiftUI
import PortsideCore

struct QRPanel: View {
    @Environment(AppModel.self) private var model
    let server: DevServer
    let dismiss: () -> Void

    @State private var share: ActiveShare?
    @State private var copied = false

    var body: some View {
        VStack(spacing: 10) {
            if let share {
                if let qr = QRCodeMaker.image(for: share.url.absoluteString, sidePoints: 148) {
                    Image(nsImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 148, height: 148)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                }

                Text(share.url.absoluteString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)

                Text(share.isRelayed
                     ? "Relayed by Portside — phone and Mac must share a Wi-Fi network."
                     : "This server already listens on your network address.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    Button(copied ? "Copied" : "Copy URL") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(share.url.absoluteString, forType: .string)
                        copied = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.2))
                            copied = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Done") {
                        if share.isRelayed { model.stopSharing(port: server.port) }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                Label("Couldn't reach the local network", systemImage: "wifi.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.045))
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .task { share = await model.startSharing(server) }
    }
}
