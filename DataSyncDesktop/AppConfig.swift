//
//  AppConfig.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import Foundation

// MARK: - App Stage Enum
enum AppStageEnum: String, SimpleEnum {
    case development, production, staging, testing
}

// MARK: - Bypass Enum  
enum BypassEnum: String, SimpleEnum {
    case bypass, `true`, `false`
}

enum AppConfig {
    // Development Config
    static let appStage: AppStageEnum = .development
    static let appDebug: Bool = true
    static let onboardingBypass: BypassEnum = .bypass
    static let paywallBypass: BypassEnum = .bypass
    
    // Dev Info
    static let devEmail: String = "240designworks@gmail.com"   
    static let devUsername: String = "Gold240sx"
    static let devPassword: String = "qirbiC-migboq-nuvki3"

    // Support
    static let supportEmail: String = "support@devspace.app"

    // Socials
    static let appWebsite: URL? = URL(string: "https://devspace.app")
    static let youtubeChannelURL: URL? = URL(string: "https://www.youtube.com/@devspaceapp")

    // Moderation
    static let modUserIds: [String] = [
        "dev-user-id"
    ]
}
