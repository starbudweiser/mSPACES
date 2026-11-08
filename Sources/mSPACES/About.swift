import AppKit

@MainActor
enum About {
    private static var window: NSWindow?
    private static let textWidth: CGFloat = 300

    static func show() {
        if window == nil { window = makeWindow() }
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private static func label(_ text: String, size: CGFloat = 12, bold: Bool = false, secondary: Bool = false) -> NSTextField {
        let f = NSTextField(wrappingLabelWithString: text)
        f.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        f.textColor = secondary ? .secondaryLabelColor : .labelColor
        f.alignment = .center
        f.preferredMaxLayoutWidth = textWidth
        f.isSelectable = false
        f.translatesAutoresizingMaskIntoConstraints = false
        f.widthAnchor.constraint(lessThanOrEqualToConstant: textWidth).isActive = true
        return f
    }

    private static func makeWindow() -> NSWindow {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 84).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 84).isActive = true
        let views: [NSView] = [icon, label("mSPACES", size: 17, bold: true), label(L("about.version", version), secondary: true),
                               label(L("about.tagline")), label(L("about.help"), secondary: true)]
        let stack = NSStackView(views: views)
        stack.orientation = .vertical; stack.alignment = .centerX; stack.spacing = 12
        stack.setCustomSpacing(6, after: views[1]); stack.setCustomSpacing(18, after: views[2])
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 28, bottom: 28, right: 28)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalToConstant: textWidth + 56).isActive = true
        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = L("about"); w.isReleasedWhenClosed = false
        let content = NSView(); content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor), stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor), stack.bottomAnchor.constraint(equalTo: content.bottomAnchor)])
        w.contentView = content
        content.layoutSubtreeIfNeeded(); content.layoutSubtreeIfNeeded()
        w.setContentSize(content.fittingSize)
        return w
    }
}
