//
//  DataSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// MARK: - Data Schema Registry

// Main data schema registry
class DataSchemaRegistry {
    static let shared = DataSchemaRegistry()
    
    private init() {}
    
    // Define all table schemas here
    lazy var tableSchemas: [TableSchema] = [
        ProjectsSchema.schema,
        userPublicSchema,
        userPrivateSchema
    ]
    
    // MARK: - Individual Table Schemas
    // (Leave these out if not needed here)

    // MARK: - Helper Methods
    
    func schema(for tableName: String) -> TableSchema? {
        return tableSchemas.first { $0.tableName == tableName }
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
}