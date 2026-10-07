import Foundation

/// User preferences, persisted in UserDefaults.
enum Settings {
    private static let defaults = UserDefaults.standard

    static let startAngleRange = 40.0...120.0
    static let fullAngleRange = 5.0...60.0
    static let blurRange = 10.0...100.0
    static let dimRange = 0.0...90.0

    static var enabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
    }

    /// When on, moving the pointer fades the blur away until the lid is raised again.
    static var mouseClearsBlur: Bool {
        get { defaults.bool(forKey: "mouseClearsBlur") }
        set { defaults.set(newValue, forKey: "mouseClearsBlur") }
    }

    /// Lid angle where blur begins.
    static var startAngle: Int {
        get { defaults.object(forKey: "startAngle") as? Int ?? 70 }
        set { defaults.set(newValue, forKey: "startAngle") }
    }

    /// Lid angle where blur reaches full strength.
    static var fullAngle: Int {
        get { defaults.object(forKey: "fullAngle") as? Int ?? 25 }
        set { defaults.set(newValue, forKey: "fullAngle") }
    }

    /// Blur radius at full strength.
    static var blur: Int {
        get { defaults.object(forKey: "blur") as? Int ?? 64 }
        set { defaults.set(newValue, forKey: "blur") }
    }

    /// Darkening at full strength, in percent.
    static var dim: Int {
        get { defaults.object(forKey: "dim") as? Int ?? 45 }
        set { defaults.set(newValue, forKey: "dim") }
    }

    /// Restores the slider values to their defaults.
    static func resetSliders() {
        for key in ["startAngle", "fullAngle", "blur", "dim"] {
            defaults.removeObject(forKey: key)
        }
    }
}
