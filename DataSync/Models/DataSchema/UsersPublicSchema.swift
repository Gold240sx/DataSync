//
//  UsersPublicSchema.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

struct UsersPublicSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "UsersPublic",
        values: [
            TableValue(
                name: "id",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit],
                unique: true
            )
            // Add more fields as needed
        ],
        primaryKey: "id"
    )
}