//
//  SchemaHelpers.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

class SchemaHelpers {
    static let shared = SchemaHelpers()
    
    private init() {}
    
    // Get all schemas
    lazy var allSchemas: [TableSchema] = [
        ProjectsSchema.schema,
        userPublicSchema,
        userPrivateSchema
    ]
    
    // MARK: - Helper Methods
    
    func schema(for tableName: String) -> TableSchema? {
        return allSchemas.first { $0.tableName == tableName }
    }
    
    func syncOptions(for tableName: String, fieldName: String) -> Set<DataSyncOption>? {
        guard let table = schema(for: tableName) else { return nil }
        return table.values.first { $0.name == fieldName }?.syncOptions
    }
    
    func isEncrypted(for tableName: String, fieldName: String) -> Bool? {
        guard let table = schema(for: tableName) else { return nil }
        return table.values.first { $0.name == fieldName }?.encrypted
    }
    
    func cloudKitContainers(for tableName: String, fieldName: String) -> Set<CloudKitContainer>? {
        guard let table = schema(for: tableName) else { return nil }
        return table.values.first { $0.name == fieldName }?.cloudKitContainer
    }
    
    func isUnique(for tableName: String, fieldName: String) -> Bool? {
        guard let table = schema(for: tableName) else { return nil }
        return table.values.first { $0.name == fieldName }?.unique
    }
    
    func primaryKey(for tableName: String) -> String? {
        guard let table = schema(for: tableName) else { return nil }
        return table.primaryKey
    }
}