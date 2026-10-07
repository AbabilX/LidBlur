import AppKit

// Private WindowServer calls: the public API only offers a fixed-strength blur.
@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> Int32

@_silgen_name("CGSSetWindowBackgroundBlurRadius")
private func CGSSetWindowBackgroundBlurRadius(_ connection: Int32, _ window: Int32, _ radius: Int32) -> Int32

/// Click-through blur windows covering every screen. `setStrength(0)` removes them.
final class BlurOverlay {
    static let maxRadius = 64.0
    static let maxTint = 0.45

    private var windows: [NSWindow] = []
    private var strength = 0.0

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuild()
        }
    }

    /// 0 = no blur, 1 = full blur.
    func setStrength(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        guard abs(clamped - strength) > 0.002 || (clamped == 0) != (strength == 0) else { return }
        strength = clamped
        apply()
    }

    private func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = []
        apply()
    }

    private func apply() {
        guard strength > 0 else {
            windows.forEach { $0.orderOut(nil) }
            return
        }
        if windows.isEmpty {
            windows = NSScreen.screens.map(Self.makeWindow)
        }
        let radius = Int32((strength * Self.maxRadius).rounded())
        // Blur is only composited where the window has some alpha.
        let tint = max(0.01, strength * Self.maxTint)
        for window in windows {
            window.backgroundColor = NSColor.black.withAlphaComponent(tint)
            if !window.isVisible { window.orderFrontRegardless() }
            _ = CGSSetWindowBackgroundBlurRadius(CGSMainConnectionID(), Int32(window.windowNumber), radius)
        }
    }

    private static func makeWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.setFrame(screen.frame, display: false)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.animationBehavior = .none
        return window
    }
}
