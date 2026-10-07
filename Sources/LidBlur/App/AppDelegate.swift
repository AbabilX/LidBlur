import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let sensor = LidSensor()
    private let overlay = BlurOverlay()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var smoothedAngle: Double?
    private var previewStart: Date?
    // Mouse-to-clear state: where the pointer was when blur began, and the fade factor (1 = shown).
    private var mouseAnchor: NSPoint?
    private var mouseCleared = false
    private var reveal = 1.0

    private let angleItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let enabledItem = NSMenuItem(title: "Disable", action: #selector(toggleEnabled), keyEquivalent: "")
    private let mouseItem = NSMenuItem(title: "Mouse Movement Clears Blur", action: #selector(toggleMouseClears), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
    private var sliderItems: [SliderMenuItem] = []
    private var menuIsOpen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "LidBlur")
        enabledItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        statusItem.menu = buildMenu()

        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Blur loop

    private func tick() {
        if menuIsOpen { refreshAngleItem() }
        if let previewStart {
            let elapsed = Date().timeIntervalSince(previewStart)
            let duration = 3.0
            if elapsed >= duration {
                self.previewStart = nil
            } else {
                // Ramp up then back down.
                overlay.setStrength(sin(elapsed / duration * .pi))
                return
            }
        }

        guard Settings.enabled, builtInDisplayIsActive(), let raw = sensor.angle() else {
            smoothedAngle = nil
            resetMouseClear()
            overlay.setStrength(0)
            return
        }
        let angle = smoothedAngle.map { $0 + (raw - $0) * 0.35 } ?? raw
        smoothedAngle = angle
        let target = strength(forAngle: angle)
        overlay.setStrength(target * revealFactor(blurWanted: target > 0))
    }

    /// Fades the blur out once the pointer moves, and re-arms when the lid is raised past the start angle.
    private func revealFactor(blurWanted: Bool) -> Double {
        guard Settings.mouseClearsBlur, blurWanted else {
            resetMouseClear()
            return 1
        }
        let location = NSEvent.mouseLocation
        if let anchor = mouseAnchor {
            // A few points of slack so a bumped desk doesn't count as movement.
            if hypot(location.x - anchor.x, location.y - anchor.y) > 6 { mouseCleared = true }
        } else {
            mouseAnchor = location
        }
        // Ease toward the target over roughly a third of a second.
        reveal += ((mouseCleared ? 0 : 1) - reveal) * 0.18
        if mouseCleared, reveal < 0.01 { reveal = 0 }
        return reveal
    }

    private func resetMouseClear() {
        mouseAnchor = nil
        mouseCleared = false
        reveal = 1
    }

    private func strength(forAngle angle: Double) -> Double {
        let start = Double(Settings.startAngle)
        let full = min(Double(Settings.fullAngle), start - 1)
        return (start - angle) / (start - full)
    }

    /// False in clamshell mode, where a shut lid shouldn't blur the external display.
    private func builtInDisplayIsActive() -> Bool {
        NSScreen.screens.contains { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return false
            }
            return CGDisplayIsBuiltin(id) != 0
        }
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        enabledItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(angleItem)
        menu.addItem(.separator())

        sliderItems = [
            SliderMenuItem(
                title: "Start", symbol: "angle", range: Settings.startAngleRange,
                read: { Double(Settings.startAngle) },
                write: { Settings.startAngle = Int($0) },
                format: { "\(Int($0))°" }
            ),
            SliderMenuItem(
                title: "Full", symbol: "laptopcomputer", range: Settings.fullAngleRange,
                read: { Double(Settings.fullAngle) },
                write: { Settings.fullAngle = Int($0) },
                format: { "\(Int($0))°" }
            ),
            SliderMenuItem(
                title: "Blur", symbol: "drop", range: Settings.blurRange,
                read: { Double(Settings.blur) },
                write: { [weak self] in
                    Settings.blur = Int($0)
                    self?.overlay.refresh()
                },
                format: { "\(Int($0))" }
            ),
            SliderMenuItem(
                title: "Dim", symbol: "circle.lefthalf.filled", range: Settings.dimRange,
                read: { Double(Settings.dim) },
                write: { [weak self] in
                    Settings.dim = Int($0)
                    self?.overlay.refresh()
                },
                format: { "\(Int($0))%" }
            ),
        ]
        sliderItems.forEach(menu.addItem)
        menu.addItem(actionItem("Reset", symbol: "arrow.counterclockwise", action: #selector(resetSliders)))
        menu.addItem(.separator())

        menu.addItem(actionItem("Preview Blur", symbol: "eye", action: #selector(preview)))
        mouseItem.target = self
        menu.addItem(mouseItem)
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())

        menu.addItem(actionItem("Check for Updates…", symbol: "arrow.down.circle", action: #selector(checkForUpdates)))
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        menu.addItem(NSMenuItem(title: "Version \(version)", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit LidBlur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private func actionItem(_ title: String, symbol: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }

    func menuWillOpen(_ menu: NSMenu) {
        menuIsOpen = true
        refreshAngleItem()
        enabledItem.title = Settings.enabled ? "Disable" : "Enable"
        mouseItem.state = Settings.mouseClearsBlur ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        sliderItems.forEach { $0.reload() }
    }

    func menuDidClose(_ menu: NSMenu) {
        menuIsOpen = false
    }

    private func refreshAngleItem() {
        if let angle = sensor.angle() {
            angleItem.title = "Lid angle: \(Int(angle))°"
        } else {
            angleItem.title = "Lid sensor not found"
        }
    }

    @objc private func toggleEnabled() {
        Settings.enabled.toggle()
    }

    @objc private func toggleMouseClears() {
        Settings.mouseClearsBlur.toggle()
    }

    @objc private func resetSliders() {
        Settings.resetSliders()
        overlay.refresh()
    }

    @objc private func preview() {
        previewStart = Date()
    }

    @objc private func checkForUpdates() {
        if let url = URL(string: "https://github.com/AbabilX/LidBlur/releases") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}
