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
    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let mouseItem = NSMenuItem(title: "Mouse Movement Clears Blur", action: #selector(toggleMouseClears), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
    private let startMenu = NSMenu()
    private let fullMenu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "LidBlur")
        statusItem.menu = buildMenu()

        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Blur loop

    private func tick() {
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
        menu.addItem(angleItem)
        menu.addItem(.separator())

        enabledItem.target = self
        menu.addItem(enabledItem)

        let startItem = NSMenuItem(title: "Start Blur At", action: nil, keyEquivalent: "")
        startItem.submenu = startMenu
        for angle in Settings.startAngleChoices {
            let item = NSMenuItem(title: "\(angle)°", action: #selector(pickStartAngle(_:)), keyEquivalent: "")
            item.target = self
            item.tag = angle
            startMenu.addItem(item)
        }
        menu.addItem(startItem)

        let fullItem = NSMenuItem(title: "Full Blur At", action: nil, keyEquivalent: "")
        fullItem.submenu = fullMenu
        for angle in Settings.fullAngleChoices {
            let item = NSMenuItem(title: "\(angle)°", action: #selector(pickFullAngle(_:)), keyEquivalent: "")
            item.target = self
            item.tag = angle
            fullMenu.addItem(item)
        }
        menu.addItem(fullItem)

        mouseItem.target = self
        menu.addItem(mouseItem)

        let previewItem = NSMenuItem(title: "Preview Blur", action: #selector(preview), keyEquivalent: "")
        previewItem.target = self
        menu.addItem(previewItem)

        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem(title: "Quit LidBlur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        if let angle = sensor.angle() {
            angleItem.title = "Lid angle: \(Int(angle))°"
        } else {
            angleItem.title = "Lid sensor not found"
        }
        enabledItem.state = Settings.enabled ? .on : .off
        mouseItem.state = Settings.mouseClearsBlur ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        for item in startMenu.items { item.state = item.tag == Settings.startAngle ? .on : .off }
        for item in fullMenu.items { item.state = item.tag == Settings.fullAngle ? .on : .off }
    }

    @objc private func toggleEnabled() {
        Settings.enabled.toggle()
    }

    @objc private func toggleMouseClears() {
        Settings.mouseClearsBlur.toggle()
    }

    @objc private func pickStartAngle(_ sender: NSMenuItem) {
        Settings.startAngle = sender.tag
    }

    @objc private func pickFullAngle(_ sender: NSMenuItem) {
        Settings.fullAngle = sender.tag
    }

    @objc private func preview() {
        previewStart = Date()
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
