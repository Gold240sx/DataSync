//
//  DataSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// MARK: - Data Schema Registry

// Main data schema registry - delegates to SchemaHelpers for consistency
class DataSchemaRegistry {
    static let shared = DataSchemaRegistry()
    
    private init() {}
    
    // Delegate to SchemaHelpers for all schema operations
    var tableSchemas: [TableSchema] {
        return SchemaHelpers.shared.allSchemas
    }
    
    func schema(for tableName: String) -> TableSchema? {
        return SchemaHelpers.shared.schema(for: tableName)
    }
    
    func syncOptions(for tableName: String, fieldName: String) -> Set<DataSyncOption>? {
        return SchemaHelpers.shared.syncOptions(for: tableName, fieldName: fieldName)
    }
    
    func isEncrypted(for tableName: String, fieldName: String) -> Bool? {
        return SchemaHelpers.shared.isEncrypted(for: tableName, fieldName: fieldName)
    }
    
    func cloudKitContainers(for tableName: String, fieldName: String) -> Set<CloudKitContainer>? {
        return SchemaHelpers.shared.cloudKitContainers(for: tableName, fieldName: fieldName)
    }
}
