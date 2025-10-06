//
//  SchemaTypes.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// Enum for data sync options
enum DataSyncOption: String, CaseIterable {
    case swiftData = "SwiftData"
    case cloudKit = "CloudKit"
    case supabase = "Supabase"
    case all = "All"
    
    // Combined options
    static let swiftDataAndCloudKit: Set<DataSyncOption> = [.swiftData, .cloudKit]
}

// Enum for CloudKit containers
enum CloudKitContainer: String, CaseIterable {
    case `public` = "Public"
    case `private` = "Private"
    case shared = "Shared"
    
    // Combined options
    static let publicAndPrivate: Set<CloudKitContainer> = [.public, .private]
    static let sharedAndPrivate: Set<CloudKitContainer> = [.shared, .private]
}

// Structure to define a table value/schema
struct TableValue {
    let id: UUID
    let name: String
    let dataType: String
    let encrypted: Bool
    let supabaseColumnName: String?
    let cloudKitContainer: Set<CloudKitContainer>?
    let syncOptions: Set<DataSyncOption>
    let unique: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        dataType: String,
        encrypted: Bool = false,
        supabaseColumnName: String? = nil,
        cloudKitContainer: Set<CloudKitContainer>? = nil,
        syncOptions: Set<DataSyncOption>,
        unique: Bool = false
    ) {
        self.id = id
        self.name = name
        self.dataType = dataType
        self.encrypted = encrypted
        self.supabaseColumnName = supabaseColumnName
        self.cloudKitContainer = cloudKitContainer
        self.syncOptions = syncOptions
        self.unique = unique
    }
}

// Structure to define a complete table schema
struct TableSchema {
    let tableName: String
    let values: [TableValue]
    let primaryKey: String?
    
    init(tableName: String, values: [TableValue], primaryKey: String? = nil) {
        self.tableName = tableName
        self.values = values
        self.primaryKey = primaryKey
    }
}

// MARK: - Data Type Enum

enum DataType: String, SimpleEnum { 
    case string, number, boolean, date, uuid, data
}