import AppKit

/// Mise à jour automatique depuis les releases GitHub : recherche quotidienne, vérification de la signature
/// (même Team ID que l'appli en cours), remplacement puis relance.
@MainActor
final class Updater {
    static let repo = "starbudweiser/mSPACES"
    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var busy = false

    var autoInstall: Bool {
        get { defaults.object(forKey: "autoUpdate") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoUpdate") }
    }

    func start() {
        // Contrôle au lancement si le dernier date de plus de 24 h, puis toutes les heures on re-teste l'échéance.
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkIfDue() }
        }
        checkIfDue()
    }

    private func checkIfDue() {
        let last = defaults.double(forKey: "lastUpdateCheck")
        if Date().timeIntervalSince1970 - last > 86_400 { Task { await check(manual: false) } }
    }

    func checkNow() { Task { await check(manual: true) } }

    private struct Release: Decodable {
        struct Asset: Decodable { let name: String; let browser_download_url: String }
        let tag_name: String
        let assets: [Asset]
    }

    private func check(manual: Bool) async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        defaults.set(Date().timeIntervalSince1970, forKey: "lastUpdateCheck")
        do {
            var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!)
            req.setValue("mSPACES-updater", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            let rel = try JSONDecoder().decode(Release.self, from: data)
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            let latest = rel.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            guard latest.compare(current, options: .numeric) == .orderedDescending,
                  let asset = rel.assets.first(where: { $0.name.hasSuffix(".zip") }) else {
                if manual { alert(L("upd.none")) }
                return
            }
            if !autoInstall && !manual {
                guard confirm(L("upd.available", latest)) else { return }
            } else if manual && !autoInstall {
                guard confirm(L("upd.available", latest)) else { return }
            }
            try await install(from: asset.browser_download_url)
        } catch {
            if manual { alert(L("upd.error")) }
        }
    }

    private func install(from urlString: String) async throws {
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appendingPathComponent("mSPACES-update-\(UUID().uuidString)")
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        let (tmp, _) = try await URLSession.shared.download(from: URL(string: urlString)!)
        let zip = work.appendingPathComponent("u.zip")
        try fm.moveItem(at: tmp, to: zip)
        try run("/usr/bin/ditto", ["-x", "-k", zip.path, work.path])
        guard let newApp = try fm.contentsOfDirectory(at: work, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) else { throw CocoaError(.fileReadCorruptFile) }
        try run("/usr/bin/codesign", ["--verify", "--deep", "--strict", newApp.path])
        guard let team = teamID(Bundle.main.bundleURL.path), teamID(newApp.path) == team else { throw CocoaError(.fileReadNoPermission) }
        // Remplacement après la fin de l'appli, puis relance.
        let dest = Bundle.main.bundleURL.path
        let script = "while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.3; done; rm -rf '\(dest)' && cp -R '\(newApp.path)' '\(dest)' && open '\(dest)'; rm -rf '\(work.path)'"
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh"); p.arguments = ["-c", script]
        try p.run()
        NSApp.terminate(nil)
    }

    private func teamID(_ path: String) -> String? {
        let p = Process(); let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/codesign"); p.arguments = ["-dv", path]
        p.standardError = pipe; p.standardOutput = pipe
        try? p.run(); p.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let id = out.split(separator: "\n").first { $0.hasPrefix("TeamIdentifier=") }.map { String($0.dropFirst(15)) }
        return (id == nil || id == "not set") ? nil : id
    }

    private func run(_ exe: String, _ args: [String]) throws {
        let p = Process(); p.executableURL = URL(fileURLWithPath: exe); p.arguments = args
        try p.run(); p.waitUntilExit()
        if p.terminationStatus != 0 { throw CocoaError(.fileReadCorruptFile) }
    }

    private func alert(_ text: String) {
        let a = NSAlert(); a.messageText = "mSPACES"; a.informativeText = text
        NSApp.activate(ignoringOtherApps: true); a.runModal()
    }
    private func confirm(_ text: String) -> Bool {
        let a = NSAlert(); a.messageText = "mSPACES"; a.informativeText = text
        a.addButton(withTitle: L("upd.install")); a.addButton(withTitle: L("upd.later"))
        NSApp.activate(ignoringOtherApps: true); return a.runModal() == .alertFirstButtonReturn
    }
}
