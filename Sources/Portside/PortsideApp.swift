import SwiftUI

struct PortsideApp: App {
    @State private var model = AppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environment(model)
        } label: {
            Image(systemName: "rectangle.stack.badge.play")
        }
        .menuBarExtraStyle(.window)
    }
}
