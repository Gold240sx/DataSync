//
//  SimpleEnums.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// MARK: - Simple Enum Protocol

protocol SimpleEnum: CaseIterable, RawRepresentable where RawValue == String {
    static var values: [String] { get }
    static func isValid(_ value: String) -> Bool
    static func from(string: String) -> Self?
}

extension SimpleEnum {
    static var values: [String] {
        return Self.allCases.map { $0.rawValue }
    }
    
    static func isValid(_ value: String) -> Bool {
        return values.contains(where: { $0.lowercased() == value.lowercased() })
    }
    
    static func from(string: String) -> Self? {
        return Self(rawValue: string)
    }
}

// MARK: - Auto Raw Value Extension

extension SimpleEnum where Self.RawValue == String {
    init?(rawValue: String) {
        // Find the case that matches the raw value (case-insensitive)
        for enumCase in Self.allCases {
            if enumCase.rawValue.lowercased() == rawValue.lowercased() {
                self = enumCase
                return
            }
        }
        return nil
    }
}

// MARK: - String Extensions

extension String {
    func matches<T: SimpleEnum>(_ enumType: T.Type) -> Bool {
        return enumType.isValid(self)
    }
    
    func asEnum<T: SimpleEnum>(_ enumType: T.Type) -> T? {
        return enumType.from(string: self)
    }
}

// MARK: - Array-based Enum Creator

/// Create a SimpleEnum from an array of strings
/// Usage: let MyEnum = createSimpleEnum(["value1", "value2", "value3"])
func createSimpleEnum(_ values: [String]) -> [String] {
    return values
}

/// Create a SimpleEnum type from an array of strings
/// This is a placeholder for a more advanced implementation
struct SimpleEnumBuilder {
    static func create<T: SimpleEnum>(_ type: T.Type, from values: [String]) -> T? {
        return nil
    }
}

