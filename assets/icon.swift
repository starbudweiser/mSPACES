import AppKit
let s: CGFloat = 1024
let img = NSImage(size: NSSize(width: s, height: s), flipped: false) { r in
    NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1).setFill()
    NSBezierPath(roundedRect: r.insetBy(dx: 40, dy: 40), xRadius: 220, yRadius: 220).fill()
    NSColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 120, y: 600, width: 784, height: 150), xRadius: 40, yRadius: 40).fill()
    let amber = NSColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
    NSColor(white: 0.85, alpha: 1).setFill()
    for x in [190, 320, 640, 770] { NSBezierPath(ovalIn: NSRect(x: x, y: 640, width: 70, height: 70)).fill() }
    amber.setFill()
    NSBezierPath(roundedRect: NSRect(x: 480, y: 610, width: 64, height: 130), xRadius: 32, yRadius: 32).fill()
    return true
}
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
