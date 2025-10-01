//
//  UsersSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// MARK: - User Schema Definitions

// Public user schema - data that can be shared publicly
let userPublicSchema = TableSchema(
    tableName: "users_public",
    values: [
        TableValue(
            name: "id",
            dataType: "UUID",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        ),
        TableValue(
            name: "username",
            dataType: "String",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        ),
        TableValue(
            name: "display_name",
            dataType: "String",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        ),
        TableValue(
            name: "avatar_url",
            dataType: "String",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        ),
        TableValue(
            name: "created_at",
            dataType: "Date",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        )
    ],
    primaryKey: "id"
)

// Private user schema - data that should remain private
let userPrivateSchema = TableSchema(
    tableName: "users_private",
    values: [
        TableValue(
            name: "user_id",
            dataType: "UUID",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        ),
        TableValue(
            name: "email",
            dataType: "String",
            encrypted: true,
            syncOptions: [.swiftData, .cloudKit, .supabase]
        ),
        TableValue(
            name: "phone_number",
            dataType: "String",
            encrypted: true,
            syncOptions: [.swiftData, .cloudKit]
        ),
        TableValue(
            name: "preferences",
            dataType: "Data",
            encrypted: true,
            syncOptions: [.swiftData, .cloudKit]
        ),
        TableValue(
            name: "last_login",
            dataType: "Date",
            syncOptions: [.swiftData, .cloudKit, .supabase]
        )
    ],
    primaryKey: "user_id"
)