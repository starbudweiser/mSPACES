import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let manager = SeparatorManager()
    func applicationDidFinishLaunching(_ notification: Notification) { manager.start() }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
