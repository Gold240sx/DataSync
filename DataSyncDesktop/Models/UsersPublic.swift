//
//  UserPublic.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation
import SwiftData

@Model
final class UsersPublic {
    var id: UUID
    var username: String
    var displayName: String
    var avatarUrl: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        avatarUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
    }
}