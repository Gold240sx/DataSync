//
//  UsersSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

struct UsersPrivateSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "users_private",
        values: [
            TableValue(
                name: "user_id",
                dataType: "UUID",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: true
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
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "auth_provider",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "jwt_expires_at",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit]
            )
        ],
        primaryKey: "user_id"
    )
}


struct UsersPublicSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "users_public",
        values: [
            TableValue(
                name: "id",
                dataType: "UUID",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: true
            ),
            TableValue(
                name: "username",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "display_name",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "avatar_url",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "created_at",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "signup_source",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "is_verified",
                dataType: "Bool",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            )
        ],
        primaryKey: "id"
    )
}
