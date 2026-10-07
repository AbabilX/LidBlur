import Foundation
import IOKit.hid

/// Reads the MacBook hinge angle from the built-in lid angle sensor (HID sensor page, usage 0x8A).
final class LidSensor {
    private static let vendorID = 0x05AC
    private static let productID = 0x8104
    private static let usagePage = 0x0020
    private static let usage = 0x008A
    private static let reportID: CFIndex = 1

    private let manager: IOHIDManager
    private var device: IOHIDDevice?

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: Self.vendorID,
            kIOHIDProductIDKey: Self.productID,
            kIOHIDPrimaryUsagePageKey: Self.usagePage,
            kIOHIDPrimaryUsageKey: Self.usage,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        device = findDevice()
    }

    var isAvailable: Bool { device != nil }

    /// Hinge angle in degrees (0 = shut), or nil if the sensor can't be read.
    func angle() -> Double? {
        if device == nil { device = findDevice() }
        guard let device else { return nil }
        guard let value = Self.read(device) else {
            self.device = nil
            return nil
        }
        return value
    }

    private func findDevice() -> IOHIDDevice? {
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return nil }
        for candidate in devices {
            guard IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { continue }
            if Self.read(candidate) != nil { return candidate }
            IOHIDDeviceClose(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        return nil
    }

    private static func read(_ device: IOHIDDevice) -> Double? {
        var report = [UInt8](repeating: 0, count: 8)
        var length = report.count
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, reportID, &report, &length)
        guard result == kIOReturnSuccess, length >= 3 else { return nil }
        let raw = UInt16(report[1]) | (UInt16(report[2]) << 8)
        return Double(raw)
    }
}
