import XCTest
@testable import DataSync

final class ENVTests: XCTestCase {
    func testPrintENVKeysAndValues() {
        let envTest = loadENV(map: ENVMap, showLogs: false)
        var missingOrEmpty: [String] = []

        print("==== ENV keys/values ====")
        for key in ENVMap.keys {
            let value = envTest.vars[key] ?? ""
            if value.isEmpty {
                print("MISSING OR EMPTY: \(key)")
                missingOrEmpty.append(key)
            } else {
                print("\(key): \(value)")
            }
        }
        print("=========================")

        if !missingOrEmpty.isEmpty {
            XCTFail("The following ENV variables are missing or empty: \(missingOrEmpty)")
        }
    }
}