//
//  UsersPrivateSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

struct UsersPrivateSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "UsersPrivate",
        values: [
            TableValue(
                name: "id",
                dataType: "String",
                encrypted: true,
                syncOptions: [.swiftData],
                unique: true
            )
            // Add more fields as needed
        ],
        primaryKey: "id"
    )
}