//
//  UserPublic.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation
import SwiftData

@Model
final class UsersPrivate {
    var userId: UUID
    var email: String
    var phoneNumber: String?
    var preferences: Data?
    var lastLogin: Date?

    init(
        userId: UUID = UUID(),
        email: String,
        phoneNumber: String? = nil,
        preferences: Data? = nil,
        lastLogin: Date? = nil
    ) {
        self.userId = userId
        self.email = email
        self.phoneNumber = phoneNumber
        self.preferences = preferences
        self.lastLogin = lastLogin
    }
}