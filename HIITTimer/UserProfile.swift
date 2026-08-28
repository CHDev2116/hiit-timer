import Foundation

/// Locally stored data used for calorie estimation.
struct UserProfile: Equatable, Codable {
    var weightKg: Double?

    private static let storageKey = "userProfile.v1"
    private static let defaults = UserDefaults.standard

    static func load() -> UserProfile {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return decoded.sanitized()
    }

    func save() {
        let profile = sanitized()
        guard let data = try? JSONEncoder().encode(profile) else { return }
        Self.defaults.set(data, forKey: Self.storageKey)
    }

    func sanitized() -> UserProfile {
        var copy = self
        if let weight = copy.weightKg, !(weight > 0) {
            copy.weightKg = nil
        }
        return copy
    }
}
