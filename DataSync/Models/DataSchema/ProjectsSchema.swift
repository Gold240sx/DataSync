//
//  ProjectsSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

struct ProjectsSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "Project",
        values: [
            TableValue(
                name: "ID",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: true
            ),
            TableValue(
                name: "logo",
                dataType: "NSObjectFileImage?",
                encrypted: true,
                cloudKitContainer: [.private],
                syncOptions: [.swiftData, .cloudKit],
                unique: false
            ),
            TableValue(
                name: "logo_url",
                dataType: "String",
                encrypted: true,
                syncOptions: [.all],
                unique: false
            ),
            TableValue(
                name: "project_name",
                dataType: "String",
                encrypted: true,
                supabaseColumnName: "project_name",
                cloudKitContainer: [.private],
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: false
            ),
            TableValue(
                name: "project_description",
                dataType: "String",
                encrypted: true,
                supabaseColumnName: "project_description",
                cloudKitContainer: [.private],
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: false
            ),
            TableValue(
                name: "created_at",
                dataType: "Date",
                encrypted: false,
                supabaseColumnName: "created_at",
                cloudKitContainer: [.private],
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: false
            ),
            TableValue(
                name: "updated_at",
                dataType: "Date?",
                encrypted: false,
                supabaseColumnName: "updated_at",
                cloudKitContainer: [.private],
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: false
            )
        ],
        primaryKey: "ID"
    )
}