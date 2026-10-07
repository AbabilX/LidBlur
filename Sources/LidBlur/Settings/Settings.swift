import Foundation

/// User preferences, persisted in UserDefaults.
enum Settings {
    private static let defaults = UserDefaults.standard

    static let startAngleChoices = [100, 90, 80, 70, 60, 50]
    static let fullAngleChoices = [45, 35, 25, 15]

    static var enabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
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
}
