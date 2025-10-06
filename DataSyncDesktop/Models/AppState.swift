//
//  AppState.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation
import SwiftUI

// MARK: - Authentication States

enum AuthState {
    case undefined          // Initial state
    case authenticated      // User is signed in
    case unauthenticated    // User is signed out
    case notAuthenticated   // Alias for unauthenticated
    case loading           // Authentication in progress
}

// MARK: - Application State Management

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    private init() {}
    
    // MARK: - Authentication State
    @Published var authState: AuthState = .undefined
    @Published var isLoggedIn: Bool = false
    @Published var showMainApp: Bool = false
    @Published var showWelcome: Bool = true
    
    // MARK: - User Profile
    @Published var userProfile: UserProfile?
    @Published var userAvatarURL: String?
    @Published var usersPublicAvatarURL: String?
    @Published var usersPublicUsername: String?
    
    // MARK: - Session Management
    @Published var isJWTExpired: Bool = false
    
    // MARK: - Authentication Methods
    
    func setAuthenticated(_ authenticated: Bool) {
        isLoggedIn = authenticated
        showMainApp = authenticated
        showWelcome = !authenticated
        authState = authenticated ? .authenticated : .notAuthenticated
    }
    
    func setLoading(_ loading: Bool) {
        authState = loading ? .loading : .undefined
    }
    
    func setJWTExpired(_ expired: Bool) {
        isJWTExpired = expired
    }
    
    func resetAuthState() {
        authState = .notAuthenticated
        isLoggedIn = false
        showMainApp = false
        showWelcome = true
        userProfile = nil
        userAvatarURL = nil
        usersPublicAvatarURL = nil
        usersPublicUsername = nil
        isJWTExpired = false
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let username: String?
    let fullName: String?
    let avatarURL: String?
    let createdAt: Date
    let updatedAt: Date?
    
    init(
        id: UUID = UUID(),
        email: String,
        username: String? = nil,
        fullName: String? = nil,
        avatarURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
