import Foundation

let ENVMap: [String: String] = [
    "supabaseUrl": "SUPABASE_URL",
    "supabasePublishableKey": "SUPABASE_PUBLISHABLE_KEY",
    "supabaseSecretKey": "SUPABASE_SECRET_KEY",
    "gitClientId": "GIDClientID",
    "devUserId": "DEV_USER_ID",
    "devPassword": "DEV_PASSWORD"
]

@dynamicMemberLookup
struct EnvContainer {
    let vars: [String: String]

    subscript(dynamicMember member: String) -> String {
        vars[member] ?? ""
    }
}

func loadENV(map: [String: String], showLogs: Bool = true) -> EnvContainer {
    var out: [String: String] = [:]
    var missing: [String] = []
    for (varName, plistKey) in map {
        let value = Bundle.main.object(forInfoDictionaryKey: plistKey)
        if let string = value as? String {
            if showLogs { print("✅ ENV: \(varName) (\(plistKey)) = \(string)") }
            out[varName] = string
        } else if let actual = value {
            if showLogs { print("⚠️ ENV WARNING: \(varName) (\(plistKey)) found, but value is not String. Received: \(actual) (\(type(of: actual)))") }
        } else {
            if showLogs { print("⚠️ ENV WARNING: \(varName) (\(plistKey)) missing in Info.plist.") }
            missing.append(varName)
        }
    }
    if missing.isEmpty && showLogs {
        print("✅ All ENV variables loaded successfully.")
    }
    return EnvContainer(vars: out)
}

// Production use
let ENV = loadENV(map: ENVMap, showLogs: true)

// For testing: (no reason to duplicate - reuse code as needed)
let ENVTest = loadENV(map: ENVMap, showLogs: false)

// USAGE: ENV.supabaseUrl, ENV.supabasePublishableKey, etc.
