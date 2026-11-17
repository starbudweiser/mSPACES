import AppKit
import ServiceManagement

extension SepStyle {
    static func collapsedImage(width: CGFloat) -> NSImage {
        let img = NSImage(size: NSSize(width: width, height: 18), flipped: false) { r in
            let t = NSAttributedString(string: "‹", attributes: [.font: NSFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: NSColor.black])
            let ts = t.size()
            t.draw(at: NSPoint(x: r.maxX - 6 - ts.width / 2, y: r.midY - ts.height / 2))
            return true
        }
        img.isTemplate = true
        return img
    }
}

enum SepStyle: String, CaseIterable {
    case space, tab, dot, bar, dash, long

    var glyph: String? {
        switch self { case .space, .tab: return nil; case .dot: return "."; case .bar: return "|"; case .dash: return "–"; case .long: return "—" }
    }
    var width: CGFloat { switch self { case .space: return 10; case .tab: return 34; case .dot: return 10; case .bar: return 10; case .dash: return 14; case .long: return 20 } }

    var image: NSImage {
        let size = NSSize(width: width, height: 18)
        let img = NSImage(size: size, flipped: false) { r in
            guard let g = self.glyph else { return true }
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.black]
            let t = NSAttributedString(string: g, attributes: attrs)
            let ts = t.size()
            t.draw(at: NSPoint(x: r.midX - ts.width / 2, y: r.midY - ts.height / 2))
            return true
        }
        img.isTemplate = true
        return img
    }
}

/// Gère les séparateurs : un NSStatusItem par séparateur. macOS mémorise la position de chacun (autosaveName),
/// l'utilisateur les déplace avec Cmd + glisser.
@MainActor
final class SeparatorManager: NSObject {
    private let defaults = UserDefaults.standard
    private var items: [Int: NSStatusItem] = [:]
    private let updater = Updater()

    private var ids: [Int] {
        get { defaults.array(forKey: "ids") as? [Int] ?? [] }
        set { defaults.set(newValue, forKey: "ids") }
    }
    /// Réduit : le séparateur s'allonge, macOS masque les icônes qui ne tiennent plus à sa gauche (trop long, il disparaît lui-même).
    private var collapsedLength: CGFloat { ((NSScreen.main?.frame.width ?? 1440) * 0.45).rounded() }
    private func isCollapsed(_ id: Int) -> Bool { defaults.bool(forKey: "collapsed.\(id)") }
    private func posKey(_ name: String) -> String { "NSStatusItem Preferred Position \(name)" }
    private func style(_ id: Int) -> SepStyle { SepStyle(rawValue: defaults.string(forKey: "style.\(id)") ?? "") ?? .bar }

    func start() {
        if ids.isEmpty { ids = [1]; defaults.set(2, forKey: "nextId") }
        for id in ids { items[id] = makeItem(id) }
        refresh()
        updater.start()
    }

    private func makeItem(_ id: Int) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "mSPACES.sep.\(id)"
        item.isVisible = true
        item.button?.identifier = NSUserInterfaceItemIdentifier("\(id)")
        item.button?.target = self
        item.button?.action = #selector(clicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        return item
    }

    private func refresh() {
        for (id, item) in items {
            let collapsed = isCollapsed(id)
            item.length = collapsed ? collapsedLength : style(id).width
            item.button?.image = collapsed ? SepStyle.collapsedImage(width: collapsedLength) : style(id).image
            item.button?.imagePosition = .imageOnly
            (item.button?.cell as? NSButtonCell)?.imageScaling = .scaleNone
            item.button?.toolTip = L("hint")
        }
    }

    /// Menu ouvert à la main sous l'icône (jamais statusItem.menu : mal placé sur plusieurs écrans).
    @objc private func clicked(_ sender: NSStatusBarButton) {
        guard let id = Int(sender.identifier?.rawValue ?? "") else { return }
        let menu = buildMenu(id)
        let x: CGFloat = isCollapsed(id) ? 0 : 0
        menu.popUp(positioning: nil, at: NSPoint(x: x, y: sender.isFlipped ? sender.bounds.maxY + 4 : -4), in: sender)
    }

    private func buildMenu(_ id: Int) -> NSMenu {
        let menu = NSMenu()
        func add(_ title: String, _ action: Selector, tag: Int = 0, on: Bool = false, to m: NSMenu) {
            let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
            mi.target = self; mi.tag = tag; mi.state = on ? .on : .off
            m.addItem(mi)
        }
        add(L("new"), #selector(newSeparator), to: menu)
        add(isCollapsed(id) ? L("expand") : L("collapse"), #selector(toggleCollapse(_:)), tag: id, to: menu)
        add(L("remove"), ids.count > 1 ? #selector(removeSeparator(_:)) : #selector(noop), tag: id, to: menu)
        menu.addItem(.separator())
        if #available(macOS 14.0, *) {
            menu.addItem(NSMenuItem.sectionHeader(title: L("section")))
        } else {
            let h = NSMenuItem(title: L("section"), action: nil, keyEquivalent: ""); h.isEnabled = false; menu.addItem(h)
        }
        for (i, s) in SepStyle.allCases.enumerated() {
            add(L("st.\(s.rawValue)"), #selector(setStyle(_:)), tag: id * 100 + i, on: s == style(id), to: menu)
        }
        menu.addItem(.separator())
        add(L("login"), #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled, to: menu)
        add(L("upd.auto"), #selector(toggleAuto), on: updater.autoInstall, to: menu)
        add(L("upd.check"), #selector(checkUpdates), to: menu)
        add(L("about"), #selector(showAbout), to: menu)
        menu.addItem(.separator())
        add(L("quit"), #selector(quit), to: menu)
        return menu
    }

    @objc private func noop() {}

    @objc private func toggleCollapse(_ sender: NSMenuItem) {
        defaults.set(!isCollapsed(sender.tag), forKey: "collapsed.\(sender.tag)")
        refresh()
    }

    @objc private func newSeparator() {
        let id = defaults.integer(forKey: "nextId")
        defaults.set(id + 1, forKey: "nextId")
        ids.append(id)
        items[id] = makeItem(id)
        refresh()
    }

    @objc private func removeSeparator(_ sender: NSMenuItem) {
        let id = sender.tag
        guard ids.count > 1, let item = items.removeValue(forKey: id) else { return }
        NSStatusBar.system.removeStatusItem(item)
        defaults.removeObject(forKey: posKey("mSPACES.sep.\(id)"))
        defaults.removeObject(forKey: "collapsed.\(id)")
        ids.removeAll { $0 == id }
        refresh()
    }

    @objc private func setStyle(_ sender: NSMenuItem) {
        defaults.set(SepStyle.allCases[sender.tag % 100].rawValue, forKey: "style.\(sender.tag / 100)")
        refresh()
    }

    @objc private func toggleLogin() {
        let svc = SMAppService.mainApp
        if svc.status == .enabled { try? svc.unregister() } else { try? svc.register() }
        refresh()
    }

    @objc private func toggleAuto() { updater.autoInstall.toggle(); refresh() }
    @objc private func checkUpdates() { updater.checkNow() }
    @objc private func showAbout() { About.show() }
    @objc private func quit() { NSApp.terminate(nil) }
}
