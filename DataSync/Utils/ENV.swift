import Foundation

private let ENVMap: [String: String] = [
    "supabaseUrl": "SUPABASE_URL",
    "supabasePublishableKey": "SUPABASE_PUBLISHABLE_KEY",
    "supabaseSecretKey": "SUPABASE_SECRET_KEY"
]

enum ENV {
    static let supabaseUrl: String = {
        let key = "supabaseUrl"
        guard let plistKey = ENVMap[key],
              let value = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String else {
            print("⚠️ ENV WARNING: \(key) (\(ENVMap[key] ?? "?")) missing or invalid in Info.plist.")
            return ""
        }
        return value
    }()

    static let supabasePublishableKey: String = {
        let key = "supabasePublishableKey"
        guard let plistKey = ENVMap[key],
              let value = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String else {
            print("⚠️ ENV WARNING: \(key) (\(ENVMap[key] ?? "?")) missing or invalid in Info.plist.")
            return ""
        }
        return value
    }()

    static let supabaseSecretKey: String = {
        let key = "supabaseSecretKey"
        guard let plistKey = ENVMap[key],
              let value = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String else {
            print("⚠️ ENV WARNING: \(key) (\(ENVMap[key] ?? "?")) missing or invalid in Info.plist.")
            return ""
        }
        return value
    }()

    static let allLoaded: Bool = {
        let missing = [supabaseUrl, supabasePublishableKey, supabaseSecretKey].contains { $0.isEmpty }
        if !missing {
            print("✅ All ENV variables loaded successfully.")
        }
        return !missing
    }()
}

// Usage: ENV.supabaseUrl, ENV.supabasePublishableKey, ENV.supabaseSecretKey
