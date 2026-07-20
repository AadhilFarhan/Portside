import AppKit
import SwiftUI

/// Owns the dashboard window. The app is a menu-bar accessory; while the
/// dashboard is open it becomes a regular app (Dock icon, ⌘-Tab) and drops
/// back to accessory when the window closes.
@MainActor
final class WindowManager: NSObject, NSWindowDelegate {

    static let shared = WindowManager()
    private var window: NSWindow?

    func showDashboard(model: AppModel) {
        if let window {
            NSApp.setActivationPolicy(.regular)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let content = NSHostingView(rootView: DashboardView().environment(model))
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.contentView = content
        newWindow.title = "Portside"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.minSize = NSSize(width: 620, height: 400)
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        window = newWindow

        NSApp.setActivationPolicy(.regular)
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
