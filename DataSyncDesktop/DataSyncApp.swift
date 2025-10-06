//
//  DataSyncApp.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import SwiftUI
import SwiftData

@main
struct DataSyncApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var authController = DesktopAuthController.shared
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Add all models back
            modelContainer = try ModelContainer(for: Project.self, GlobalAppState.self, LocalAppState.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(modelContainer)
                .environmentObject(appState)
                .environmentObject(authController)
        }
    }
}

// MARK: - App Root View

struct AppRootView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var authController = DesktopAuthController.shared
    @State private var initialCheckDone = false
    
    var body: some View {
        Group {
            switch appState.authState {
            case .authenticated:
                MainAppView()
            case .notAuthenticated, .unauthenticated:
                AuthView()
            case .undefined, .loading:
                LoadingView()
                    .onAppear {
                        // Force transition after a brief delay if still loading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if appState.authState == .loading || appState.authState == .undefined {
                                // If still in loading/undefined state after timeout, default to not authenticated
                                appState.setAuthenticated(false)
                            }
                        }
                    }
            }
        }
        .onAppear {
            // Initialize authentication state
            authController.startListeningToAuthState()
        }
        .onChange(of: authController.authState) { _, newState in
            // Sync auth controller state with app state
            updateAppState(newState)
        }
    }
    
    private func updateAppState(_ authState: AuthState) {
        switch authState {
        case .authenticated:
            appState.setAuthenticated(true)
            print("AppRootView: Auth state changed to authenticated")
        case .notAuthenticated, .unauthenticated:
            appState.setAuthenticated(false)
            print("AppRootView: Auth state changed to not authenticated")
        case .loading:
            appState.setLoading(true)
            print("AppRootView: Auth state changed to loading")
        case .undefined:
            // Keep current state
            print("AppRootView: Auth state is undefined")
        }
    }
    
    private func handleAuthStateChange(_ newState: AuthState) {
        switch newState {
        case .authenticated:
            appState.setAuthenticated(true)
        case .notAuthenticated, .unauthenticated:
            appState.setAuthenticated(false)
        case .loading:
            appState.setLoading(true)
        case .undefined:
            break
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing DataSync...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var authController = DesktopAuthController.shared
    @State private var userId: String = "Loading..."
    @State private var username: String = "User"
    
    var body: some View {
        NavigationView {
            VStack {
                // User profile display
                HStack(alignment: .top, spacing: 20) {
                    // Avatar image
                    VStack {
                        if let avatarURL = authController.userAvatarURL, !avatarURL.isEmpty {
                            AsyncImage(url: URL(string: avatarURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_):
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                        }
                        
                        Text(username)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: 80)
                    }
                    .frame(width: 100)
                    
                    // User ID display
                    VStack(alignment: .leading, spacing: 10) {
                        Text("User ID:")
                            .font(.headline)
                        
                        Text(userId)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                            .textSelection(.enabled)
                        
                        Divider()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding()
                
                ContentView()
                
                // Add a prominent logout button at the bottom
                LogoutButton()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
            }
            .navigationTitle("DataSync")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    UserProfileButton()
                }
            }
        }
        .onAppear {
            // Load user profile data
            Task {
                await loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() async {
        // Get user ID from the auth controller
        if let session = authController.authClient?.currentSession {
            await MainActor.run {
                userId = session.user.id.uuidString
            }
            
            // Trigger profile fetch to update other UI elements including avatar URL
            await authController.fetchUserProfile()
            
            // If avatar URL or username is not available, try to fetch it specifically
            if authController.userAvatarURL == nil || authController.usersPublicUsername == nil {
                _ = await authController.fetchUsersPublicUsername()
                
                // Debug output
                print("Avatar URL: \(authController.userAvatarURL ?? "nil")")
                print("Username: \(authController.usersPublicUsername ?? "nil")")
                
                // Update username if available
                if let fetchedUsername = authController.usersPublicUsername {
                    await MainActor.run {
                        username = fetchedUsername
                    }
                }
            } else if let fetchedUsername = authController.usersPublicUsername {
                // Update username if already available
                await MainActor.run {
                    username = fetchedUsername
                }
            }
        } else {
            await MainActor.run {
                userId = "Not signed in"
                username = "User"
            }
        }
    }
}

// MARK: - Logout Button

struct LogoutButton: View {
    @StateObject private var authController = DesktopAuthController.shared
    @StateObject private var appState = AppState.shared
    @State private var isLoggingOut = false
    
    var body: some View {
        Button("Sign Out") {
            isLoggingOut = true
            
            // First reset the app state
            appState.resetAuthState()
            
            // Then call signOut for cleanup
            Task {
                await authController.signOut()
                
                // Ensure auth state is updated
                await MainActor.run {
                    authController.authState = .notAuthenticated
                    isLoggingOut = false
                    
                    // Print for debugging
                    print("Signed out. Auth state: \(authController.authState)")
                }
            }
        }
        .foregroundColor(.red)
        .buttonStyle(.plain)
        .disabled(isLoggingOut)
        .overlay(
            isLoggingOut ? ProgressView().padding(.leading, 80) : nil
        )
    }
}

// MARK: - User Profile Button

struct UserProfileButton: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var authController = DesktopAuthController.shared
    @State private var showingProfile = false
    
    var body: some View {
        HStack(spacing: 8) {
            if let avatarURL = appState.userAvatarURL {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.usersPublicUsername ?? "User")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Signed In")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            showingProfile = true
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileView()
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    @StateObject private var authController = DesktopAuthController.shared
    @StateObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    if let avatarURL = authController.userAvatarURL {
                        AsyncImage(url: URL(string: avatarURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(authController.usersPublicUsername ?? "User")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                // Profile Actions
                VStack(spacing: 12) {
                    Button("Sign Out") {
                        // Set auth state directly to trigger navigation
                        authController.authState = .notAuthenticated
                        appState.authState = .notAuthenticated
                        dismiss()
                        
                        // Also call signOut for cleanup
                        Task {
                            await authController.signOut()
                        }
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(isSigningOut)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}