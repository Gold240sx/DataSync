//
//  AppStateModels.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation
import SwiftData

// MARK: - Sync Status Enum

enum SyncStatus: String, CaseIterable { 
    case synced, pending, failed, conflict, offline
}

// MARK: - Global App State Model (Synced to Cloud)

@Model
final class GlobalAppState {
    var userId: UUID = UUID()
    var isOnline: Bool = false
    var lastSeen: Date = Date()
    var deviceType: String = "macOS"
    var appVersion: String = "1.0.0"
    
    init(
        userId: UUID = UUID(),
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        deviceType: String = "macOS",
        appVersion: String = "1.0.0"
    ) {
        self.userId = userId
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.deviceType = deviceType
        self.appVersion = appVersion
    }
}

// MARK: - Local App State Model (SwiftData Only)

@Model
final class LocalAppState {
    var id: UUID = UUID()
    var authState: String = "notAuthenticated"
    var userProfile: Data?
    var userAvatarURL: String?
    var usersPublicUsername: String?
    var isJWTExpired: Bool = false
    var sessionToken: String?
    var refreshToken: String?
    var preferences: Data?
    var lastSyncTimestamp: Date?
    var offlineMode: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date?
    
    init(
        id: UUID = UUID(),
        authState: String = "undefined",
        userProfile: Data? = nil,
        userAvatarURL: String? = nil,
        usersPublicUsername: String? = nil,
        isJWTExpired: Bool = false,
        sessionToken: String? = nil,
        refreshToken: String? = nil,
        preferences: Data? = nil,
        lastSyncTimestamp: Date? = nil,
        offlineMode: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.authState = authState
        self.userProfile = userProfile
        self.userAvatarURL = userAvatarURL
        self.usersPublicUsername = usersPublicUsername
        self.isJWTExpired = isJWTExpired
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.preferences = preferences
        self.lastSyncTimestamp = lastSyncTimestamp
        self.offlineMode = offlineMode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Online Status Manager

class OnlineStatusManager: ObservableObject {
    static let shared = OnlineStatusManager()
    
    private init() {}
    
    @Published var isOnline: Bool = false
    @Published var lastSeen: Date = Date()
    
    func updateOnlineStatus(_ online: Bool) {
        isOnline = online
        lastSeen = Date()
        
        // Update global app state in database
        Task {
            await syncOnlineStatusToDatabase()
        }
    }
    
    private func syncOnlineStatusToDatabase() async {
        // This would sync the online status to the global database
        // Implementation depends on your database sync strategy
    }
    
    func startHeartbeat() {
        // Start periodic heartbeat to maintain online status
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateOnlineStatus(true)
        }
    }
    
    func stopHeartbeat() {
        // Stop heartbeat and mark as offline
        updateOnlineStatus(false)
    }
}
