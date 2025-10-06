// 
//  DesktopAuthController.swift
//  DevSpace-Desktop
//
//  Created by Michael Martell on 8/14/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Supabase
import GoogleSignIn

// Create a simple presentation context provider
class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// Create a simple UserDefaults-based storage to avoid Keychain prompts
class UserDefaultsLocalStorage: AuthLocalStorage, @unchecked Sendable {
    private let userDefaults = UserDefaults.standard
    private let keyPrefix = "supabase_auth_"
    
    func store(key: String, value: Data) throws {
        userDefaults.set(value, forKey: keyPrefix + key)
    }
    
    func retrieve(key: String) throws -> Data? {
        return userDefaults.data(forKey: keyPrefix + key)
    }
    
    func remove(key: String) throws {
        userDefaults.removeObject(forKey: keyPrefix + key)
    }
}

final class DesktopAuthController: ObservableObject {
    static let shared = DesktopAuthController()
    
    // Supabase configuration from Info.plist with fallback values
    private static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "https://pnunoycrixteeuxxpxqi.supabase.co"
    private static let supabasePublishableKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String ?? "sb_publishable_OBqPN_lV1uWtGZ51ETS4Nw_adEHRzk0"
    private static let supabaseSecretKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SECRET_KEY") as? String ?? "sb_secret_ZE_PO0lpf3mLFeYX9WFgjg_-jZ7Kdm_"
    
    @Published var authState: AuthState = .undefined
    @Published var userAvatarURL: String?
    @Published var usersPublicAvatarURL: String?
    @Published var usersPublicUsername: String?
    @Published var isJWTExpired: Bool = false
    private(set) var authClient: AuthClient?
    
    // MARK: - JWT Expiration Management
    
    func resetJWTExpirationStatus() {
        isJWTExpired = false
    }
    private var webAuthSession: ASWebAuthenticationSession?
    private let authPresentationProvider = AuthPresentationContextProvider()
    private var pendingUsername: String?

    init() {
        // Use Supabase configuration from Info.plist
        let urlString = Self.supabaseURL
        let publishableKey = Self.supabasePublishableKey
        
        _ = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        _ = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String
        _ = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SECRET_KEY") as? String
        
        if let url = URL(string: urlString), !publishableKey.isEmpty {
            let headers = ["Authorization": "Bearer \(publishableKey)", "apikey": publishableKey]
            
            let authURL = url.appendingPathComponent("auth/v1")
            
            let config = AuthClient.Configuration(
                url: authURL,
                headers: headers,
                flowType: .pkce,
                localStorage: UserDefaultsLocalStorage(), // Custom UserDefaults storage - no Keychain prompts
                logger: nil
            )
            self.authClient = AuthClient(configuration: config)
        
        // Test API key immediately after initialization
        Task {
            await testAPIKeyValidity()
        }
        } else {
            self.authClient = nil
        }
    }
    
    func startListeningToAuthState() {
        // Start with loading state
        DispatchQueue.main.async { [weak self] in
            self?.authState = .loading
        }
        
        guard let authClient else {
            DispatchQueue.main.async { [weak self] in
                self?.authState = .notAuthenticated
            }
            return
        }

        // Check if we have a valid session
        if let session = authClient.currentSession {
            // Verify session is still valid
            if Date(timeIntervalSince1970: session.expiresAt) > Date() {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.authState = .authenticated
                    self.refreshAvatarURLFromSession()
                }
                // Fetch profile data when we have an existing session
                Task {
                    await self.fetchUserProfile()
                    // Ensure profile rows and storage folder exist for existing sessions
                    await self.postAuthBootstrap()
                }
            } else {
                // Session expired
                DispatchQueue.main.async { [weak self] in
                    self?.authState = .notAuthenticated
                }
                // Attempt to refresh the token
                // Capture weak self for the Task to avoid reference cycles
                Task { [weak self] in
                    guard let self = self, let authClient = self.authClient else { return }
                    do {
                        _ = try await authClient.refreshSession()
                        await MainActor.run {
                            // Capture self as a local variable to avoid concurrent access
                            let capturedSelf = self
                            capturedSelf.authState = .authenticated
                        }
                    } catch {
                        await MainActor.run {
                            // Capture self as a local variable to avoid concurrent access
                            let capturedSelf = self
                            capturedSelf.authState = .notAuthenticated
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.authState = .notAuthenticated
            }
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        guard let authClient = authClient else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "AuthClient not configured"])
        }
        
        do {
            _ = try await authClient.signIn(email: email, password: password)
            
            await MainActor.run {
                self.authState = .authenticated
                self.refreshAvatarURLFromSession()
            }
            
            // Fetch profile data after successful sign-in
            await fetchUserProfile()
            // Bootstrap user profile
            await postAuthBootstrap()
        } catch {
            throw error
        }
    }
    
    @MainActor
    func signInWith(provider: Provider) async throws {
        guard let authClient else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "AuthClient not configured"])
        }
        
        let redirectScheme = "devspace" // Hardcoded for desktop
        let providerType: Provider
        switch provider {
        case .google:
            providerType = .google
        case .github:
            providerType = .github
        case .apple:
            providerType = .apple
        case .email:
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email authentication not implemented"])
        default: 
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email authentication not implemented"])
        }
        let authURL = try authClient.getOAuthSignInURL(provider: providerType)
        
        let strongSelf = self
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: redirectScheme) { callbackURL, error in
            guard let callbackURL else {
                return
            }
            Task { 
                do {
                    try await strongSelf.authClient?.session(from: callbackURL)
                    await MainActor.run {
                        strongSelf.authState = .authenticated
                        strongSelf.refreshAvatarURLFromSession()
                    }
                    // Fetch profile data after successful OAuth sign-in
                    await strongSelf.fetchUserProfile()
                    // Bootstrap user profile
                    await strongSelf.postAuthBootstrap()
                } catch {
                    // Handle error silently
                }
            }
        }
        session.presentationContextProvider = authPresentationProvider
        session.prefersEphemeralWebBrowserSession = true
        self.webAuthSession = session
        session.start()
    }
    
    func signUpWithEmail(email: String, password: String, username: String = "", fullName: String = "") async throws {
        guard let authClient = authClient else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "AuthClient not configured"])
        }
        
        // Store pending username for post-auth bootstrap
        if !username.isEmpty {
            self.pendingUsername = username
        }
        
        do {
            _ = try await authClient.signUp(email: email, password: password)
            
            await MainActor.run {
                self.authState = .authenticated
                self.refreshAvatarURLFromSession()
            }
            
            // Fetch profile data after successful sign-up
            await fetchUserProfile()
            // Bootstrap user profile with username
            await postAuthBootstrap()
        } catch {
            throw error
        }
    }

    func resetPassword(email: String) async throws {
        guard let authClient else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "AuthClient not configured"])
        }
        try await authClient.resetPasswordForEmail(email)
    }
    
    @MainActor
    func signOut() async {
        // Clear user profile data first
        self.userProfile = nil
        self.userAvatarURL = nil
        self.usersPublicAvatarURL = nil
        self.usersPublicUsername = nil
        self.pendingUsername = nil
        
        // Make a copy of authClient to avoid race conditions
        guard let authClientCopy = authClient else {
            // Even if we don't have an auth client, update the auth state
            self.authState = .notAuthenticated
            return
        }
        
        // Execute the API signout
        do { 
            try await authClientCopy.signOut()
        } catch { 
            // Log the error but continue with local sign out
            print("Error signing out: \(error)")
        }
        
        // Clear auth client and web session references
        self.webAuthSession = nil
        
        // Update auth state to prevent further authenticated API calls
        // This should be done last to ensure all cleanup is complete
        self.authState = .notAuthenticated
    }

    @MainActor
    func signInWithAppleNative(credential: ASAuthorizationAppleIDCredential) async {
        guard let authClient else {
            return
        }
        
        guard let tokenData = credential.identityToken, 
              let idToken = String(data: tokenData, encoding: .utf8) else {
            return
        }
        
        // Debug: Parse the JWT to see the audience
        // Parse JWT payload if needed for debugging
        _ = parseJWTPayload(idToken)
        
        do {
            try await authClient.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    accessToken: nil
                )
            )
            
            await MainActor.run {
                self.authState = .authenticated
                self.refreshAvatarURLFromSession()
            }
            
            // Fetch profile data after successful Apple sign-in
            await fetchUserProfile()
            // Bootstrap user profile
            await postAuthBootstrap()
        } catch {
            // More detailed error logging
            // Error details available for debugging if needed
            _ = error as NSError?
        }
    }
    
    // Helper to parse JWT payload for debugging
    private func parseJWTPayload(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        let payloadSegment = segments[1]
        guard let payloadData = base64URLDecode(payloadSegment),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }
        
        return payload
    }
    
    private func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + 4 - remainder, withPad: "=", startingAt: 0)
        }
        
        return Data(base64Encoded: base64)
    }

    @MainActor
    func signInWithGoogleNative() async {
        guard let authClient else {
            return
        }
        
        guard let presentingWindow = NSApp.keyWindow ?? NSApp.mainWindow else {
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)
            
            guard let idToken = result.user.idToken?.tokenString else {
                return
            }
            let accessToken = result.user.accessToken.tokenString
            try await authClient.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            await MainActor.run {
                self.authState = .authenticated
                self.refreshAvatarURLFromSession()
            }
            // Fetch profile data after successful Google sign-in
            await fetchUserProfile()
            // Bootstrap user profile
            await postAuthBootstrap()
        } catch {
            // Handle error silently
        }
    }
    
    private func refreshAvatarURLFromSession() {
        // Simplified for desktop
        Task {
            await fetchUserProfile()
        }
    }
    
    // Add utility methods similar to mobile version
    private func fetchValue(table: String, column: String, whereEq: (String, String), accessToken: String) async -> String? {
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return nil }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: column),
            URLQueryItem(name: whereEq.0, value: "eq.\(whereEq.1)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstResult = jsonArray.first,
               let value = firstResult[column] as? String {
                return value
            }
        } catch {
            // Handle error silently
        }
        
        return nil
    }
    
    // Add method to fetch specific user data on demand
    func fetchUsersPublicUsername() async -> String? {
        guard let session = authClient?.currentSession else { return nil }
        let userId = session.user.id.uuidString.lowercased()
        let value = await fetchValue(table: "users_public", column: "username", whereEq: ("user_id", userId), accessToken: session.accessToken)
        await MainActor.run { self.usersPublicUsername = value }
        return value
    }
    
    // MARK: - User Profile Data
    struct UserProfile: Equatable {
        // Public data
        let userId: String
        let avatarUrl: String?
        let createdAt: Date?
        let username: String?
        let signupSource: String?
        let applicationName: String?
        
        // Private data
        let email: String?
    }
    
    @Published var userProfile: UserProfile?
    
    func fetchUserProfile() async {
        guard let authClient = authClient,
              let session = authClient.currentSession else {
            return
        }
        
        let userId = session.user.id.uuidString.lowercased()
        
        // Use REST API instead of GraphQL
        async let publicData = fetchUsersPublicData(userId: userId, session: session)
        async let privateData = fetchUsersPrivateData(userId: userId, session: session)
        
        let (publicResult, privateResult) = await (publicData, privateData)
        
        await MainActor.run {
            let profile = UserProfile(
                userId: userId,
                avatarUrl: publicResult?["avatar_url"] as? String,
                createdAt: parseDate(from: publicResult?["created_at"]),
                username: publicResult?["username"] as? String,
                signupSource: publicResult?["signup_source"] as? String,
                applicationName: publicResult?["application_name"] as? String,
                email: privateResult?["email"] as? String
            )
            
            self.userProfile = profile
            self.usersPublicUsername = profile.username
            
            // Update userAvatarURL with database avatar URL if available
            if let avatarUrl = profile.avatarUrl {
                self.userAvatarURL = avatarUrl
            }
        }
    }
    
    private func fetchUsersPublicData(userId: String, session: Session) async -> [String: Any]? {
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return nil }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/users_public"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "user_id,avatar_url,created_at,username,signup_source,application_name"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200..<300).contains(httpResponse.statusCode) else {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    
                    // Check for JWT expiration
                    if httpResponse.statusCode == 401 && errorMsg.contains("JWT expired") {
                        await MainActor.run {
                            self.isJWTExpired = true
                        }
                    }
                    return nil
                }
            }
            
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstResult = jsonArray.first {
                // Reset JWT expiration flag on successful API call
                await MainActor.run {
                    self.isJWTExpired = false
                }
                return firstResult
            }
        } catch {
            // Handle error silently
        }
        
        return nil
    }
    
    private func fetchUsersPrivateData(userId: String, session: Session) async -> [String: Any]? {
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return nil }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/users_private"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "user_id,email"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200..<300).contains(httpResponse.statusCode) else {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    
                    // Check for JWT expiration
                    if httpResponse.statusCode == 401 && errorMsg.contains("JWT expired") {
                        await MainActor.run {
                            self.isJWTExpired = true
                        }
                    }
                    return nil
                }
            }
            
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstResult = jsonArray.first {
                // Reset JWT expiration flag on successful API call
                await MainActor.run {
                    self.isJWTExpired = false
                }
                return firstResult
            }
        } catch {
            // Handle error silently
        }
        
        return nil
    }

    private func parseDate(from value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.date(from: dateString) ?? {
            // Fallback without fractional seconds
            let simpleFormatter = ISO8601DateFormatter()
            return simpleFormatter.date(from: dateString)
        }()
    }

    // Add helper method to check for unique values (useful for validation)
    private func findUnique(table: String, column: String, value: String, accessToken: String) async -> Bool {
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return false }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "count"),
            URLQueryItem(name: column, value: "eq.\(value)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components?.url else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") 
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        request.setValue("exact", forHTTPHeaderField: "Prefer")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.isEmpty // true if no existing records found
            }
        } catch {
            // Handle error silently
        }
        
        return false // Assume not unique if we can't verify
    }

    // Test API key validity with a simple auth endpoint call
    private func testAPIKeyValidity() async {
        let supabaseURL = Self.supabaseURL
        let publishableKey = Self.supabasePublishableKey
        guard let baseURL = URL(string: supabaseURL) else { 
            return 
        }
        
        // Test with auth/v1/user endpoint (requires valid API key)
        let testURL = baseURL.appendingPathComponent("auth/v1/user")
        
        var request = URLRequest(url: testURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                // Status code handling
                _ = httpResponse.statusCode
            }
        } catch {
            // Handle error silently
        }
    }
    
    // Test basic API connectivity
    private func testBasicAPIConnection() async {
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("rest/v1/"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            // Check response status if needed
            _ = response as? HTTPURLResponse
        } catch {
            // Handle error silently
        }
    }
    
    // Debug method to test database connection
    func testDatabaseConnection() async {
        // Test basic API connectivity first
        await testBasicAPIConnection()
        
        guard let authClient = authClient,
              let session = authClient.currentSession else {
            return
        }
        
        let userId = session.user.id.uuidString.lowercased()
        
        // Test users_public table
        let publicResult = await fetchUsersPublicData(userId: userId, session: session)
        
        // Test users_private table  
        let privateResult = await fetchUsersPrivateData(userId: userId, session: session)
        
        // If no data exists, run the full bootstrap process
        if publicResult == nil || privateResult == nil {
            await postAuthBootstrap()
        }
    }
    
    // MARK: - Post-auth profile bootstrap
    @MainActor
    private func postAuthBootstrap() async {
        guard let session = authClient?.currentSession else { return }
        await ensureUsersPublicRow()
        await ensureUserStorageFolder()
        
        let userId = session.user.id.uuidString.lowercased()
        let email = session.user.email ?? ""
        
        await upsertUsersPublicInfo(
            userId: userId,
            applicationName: "DevSpace Desktop", // Desktop-specific application name
            signupSource: "desktop_app",
            username: pendingUsername
        )
        await upsertUsersPrivateEmail(userId: userId, email: email)
        
        // Clear pending username after processing
        self.pendingUsername = nil
    }
    
    private func upsertUsersPublicInfo(userId: String, applicationName: String, signupSource: String, username: String?) async {
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL), let session = authClient?.currentSession else { return }
        
        var req = URLRequest(url: baseURL.appendingPathComponent("rest/v1/users_public"))
        req.httpMethod = "POST"
        
        var row: [String: Any] = [
            "user_id": userId,
            "application_name": applicationName,
            "signup_source": signupSource,
        ]
        if let name = username, !name.isEmpty { 
            row["username"] = name 
        }
        
        let body: [[String: Any]] = [row]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(secretKey, forHTTPHeaderField: "apikey")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let httpResponse = response as? HTTPURLResponse {
                if !(200..<300).contains(httpResponse.statusCode) {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    
                    // Check for JWT expiration
                    if httpResponse.statusCode == 401 && errorMsg.contains("JWT expired") {
                        await MainActor.run {
                            self.isJWTExpired = true
                        }
                    }
                }
            }
        } catch {
            // Handle error silently
        }
    }
    
    private func upsertUsersPrivateEmail(userId: String, email: String) async {
        guard !email.isEmpty else { 
            return 
        }
        
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL), let session = authClient?.currentSession else { return }
        
        var req = URLRequest(url: baseURL.appendingPathComponent("rest/v1/users_private"))
        req.httpMethod = "POST"
        let body: [[String: Any]] = [[
            "user_id": userId,
            "email": email
        ]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(secretKey, forHTTPHeaderField: "apikey")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let httpResponse = response as? HTTPURLResponse {
                if !(200..<300).contains(httpResponse.statusCode) {
                    let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                    
                    // Check for JWT expiration
                    if httpResponse.statusCode == 401 && errorMsg.contains("JWT expired") {
                        await MainActor.run {
                            self.isJWTExpired = true
                        }
                    }
                }
            }
        } catch {
            // Handle error silently
        }
    }
    
    /// Ensures a row exists in public.users_public for the current user
    @MainActor
    func ensureUsersPublicRow() async {
        guard let session = authClient?.currentSession else { return }
        let userId = session.user.id.uuidString.lowercased()
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return }
        
        var req = URLRequest(url: baseURL.appendingPathComponent("rest/v1/users_public"))
        req.httpMethod = "POST"
        let body: [[String: Any]] = [["user_id": userId]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(secretKey, forHTTPHeaderField: "apikey")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            // Handle response if needed
            _ = response
        } catch {
            // Handle error silently
        }
    }
    
    /// Ensures a logical folder prefix exists for the user's avatars in Storage by uploading a .keep file
    @MainActor
    func ensureUserStorageFolder() async {
        guard let session = authClient?.currentSession else { return }
        let userId = session.user.id.uuidString
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else { return }
        
        var uploadURL = baseURL.appendingPathComponent("storage/v1/object/avatars/users/\(userId)/.keep")
        if var components = URLComponents(url: uploadURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "upsert", value: "true")]
            uploadURL = components.url ?? uploadURL
        }
        
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        // Use small non-empty payload to avoid 400 responses on empty bodies
        req.httpBody = "keep".data(using: .utf8)
        req.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                // If it's a duplicate (409), attempt a PUT overwrite without upsert param
                if http.statusCode == 409 {
                    let putURL = baseURL.appendingPathComponent("storage/v1/object/avatars/users/\(userId)/.keep")
                    var putReq = URLRequest(url: putURL)
                    putReq.httpMethod = "PUT"
                    putReq.httpBody = "keep".data(using: .utf8)
                    putReq.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    putReq.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                    putReq.setValue(secretKey, forHTTPHeaderField: "apikey")
                    let (_, presp) = try await URLSession.shared.data(for: putReq)
                    if let phttp = presp as? HTTPURLResponse, !(200..<300).contains(phttp.statusCode) {
                        // Handle error
                    } else {
                        // Success
                    }
                } else {
                    // Get error message if needed
                    _ = String(data: data, encoding: .utf8) ?? ""
                    // Handle error
                }
            } else {
                // Success
            }
        } catch {
            // Handle error silently
        }
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        guard let session = authClient?.currentSession else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No active session"])
        }
        
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Supabase URL"])
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/users_public"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "username"),
            URLQueryItem(name: "username", value: "eq.\(username)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components?.url else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.isEmpty // true if available, false if taken
            }
            
            return true // Default to available if we can't parse
        } catch {
            throw error
        }
    }
    
    func checkEmailAvailability(_ email: String) async throws -> Bool {
        guard let session = authClient?.currentSession else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No active session"])
        }
        
        let supabaseURL = Self.supabaseURL
        let secretKey = Self.supabaseSecretKey
        guard let baseURL = URL(string: supabaseURL) else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Supabase URL"])
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/users_private"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "email"),
            URLQueryItem(name: "email", value: "eq.\(email)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components?.url else {
            throw NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(secretKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.isEmpty // true if available, false if taken
            }
            
            return true // Default to available if we can't parse
        } catch {
            throw error
        }
    }
}
