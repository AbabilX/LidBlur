import AppKit

/// A menu row with an icon, a label, a slider, and a live value readout.
final class SliderMenuItem: NSMenuItem {
    private let slider: NSSlider
    private let valueLabel = NSTextField(labelWithString: "")
    private let read: () -> Double
    private let write: (Double) -> Void
    private let format: (Double) -> String

    init(
        title: String,
        symbol: String,
        range: ClosedRange<Double>,
        read: @escaping () -> Double,
        write: @escaping (Double) -> Void,
        format: @escaping (Double) -> String
    ) {
        self.read = read
        self.write = write
        self.format = format
        slider = NSSlider(value: read(), minValue: range.lowerBound, maxValue: range.upperBound, target: nil, action: nil)
        super.init(title: title, action: nil, keyEquivalent: "")

        let row = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 28))

        let icon = NSImageView(frame: NSRect(x: 16, y: 6, width: 16, height: 16))
        icon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor
        row.addSubview(icon)

        let label = NSTextField(labelWithString: title)
        label.font = .menuFont(ofSize: 0)
        label.frame = NSRect(x: 40, y: 5, width: 48, height: 18)
        row.addSubview(label)

        slider.frame = NSRect(x: 90, y: 4, width: 136, height: 20)
        slider.controlSize = .small
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(changed)
        slider.setAccessibilityLabel(title)
        row.addSubview(slider)

        valueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.frame = NSRect(x: 228, y: 6, width: 38, height: 16)
        row.addSubview(valueLabel)

        view = row
        reload()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Re-reads the stored value, e.g. after a reset.
    func reload() {
        slider.doubleValue = read()
        valueLabel.stringValue = format(slider.doubleValue)
    }

    @objc private func changed() {
        let value = slider.doubleValue.rounded()
        write(value)
        valueLabel.stringValue = format(value)
    }
}
