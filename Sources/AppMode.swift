// Два „таба“ в едно приложение: новата Саксия (по подразбиране) и архивираният живот на Пиксчо.
// Превключването записва избора и рестартира приложението.

import AppKit

enum AppMode {
    /// true: старият живот с Пиксчо; иначе: Саксията.
    static var isPixcho: Bool { UserDefaults.standard.string(forKey: "appMode") == "pixcho" }

    static func switchTo(pixcho: Bool) {
        UserDefaults.standard.set(pixcho ? "pixcho" : "pot", forKey: "appMode")
        UserDefaults.standard.synchronize()
        let q = { (s: String) in "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }
        let script = """
        while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.2; done
        open \(q(Bundle.main.bundleURL.path))
        """
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", script]
        try? p.run()
        NSApp.terminate(nil)
    }
}
