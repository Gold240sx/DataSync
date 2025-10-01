//
//  AppStateSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// MARK: - App State Schema for Global Database

struct AppStateSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "app_state",
        values: [
            TableValue(
                name: "user_id",
                dataType: "UUID",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: true
            ),
            TableValue(
                name: "is_online",
                dataType: "Bool",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "last_seen",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "device_type",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "app_version",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            )
        ],
        primaryKey: "user_id"
    )
}

// MARK: - Local App State Schema (SwiftData Only)

struct LocalAppStateSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "local_app_state",
        values: [
            TableValue(
                name: "id",
                dataType: "UUID",
                encrypted: false,
                syncOptions: [.swiftData], // SwiftData only - never synced
                unique: true
            ),
            TableValue(
                name: "auth_state",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "user_profile",
                dataType: "Data",
                encrypted: true,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "user_avatar_url",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "users_public_username",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "is_jwt_expired",
                dataType: "Bool",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "session_token",
                dataType: "String",
                encrypted: true,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "refresh_token",
                dataType: "String",
                encrypted: true,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "preferences",
                dataType: "Data",
                encrypted: true,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "last_sync_timestamp",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "offline_mode",
                dataType: "Bool",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "created_at",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            ),
            TableValue(
                name: "updated_at",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData] // SwiftData only
            )
        ],
        primaryKey: "id"
    )
}
