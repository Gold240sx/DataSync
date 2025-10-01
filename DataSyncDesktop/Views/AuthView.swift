//
//  AuthView.swift
//  DataSync
//
//  Created by Michael Martell on 9/30/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthView: View {
    @StateObject private var authController = DesktopAuthController.shared
    @StateObject private var appState = AppState.shared
    
    @State private var email = AppConfig.appDebug ? AppConfig.devEmail : ""
    @State private var password = AppConfig.appDebug ? AppConfig.devPassword : ""
    @State private var username = AppConfig.appDebug ? "Gold240sx" : ""
    @State private var fullName = ""
    @State private var error: String?
    @State private var isLoading = false
    @State private var isSignUp = false
    
    // Debug counter for tracking auth attempts
    @State private var authAttemptCount = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("DataSync")
                    .font(.largeTitle.bold())
                
                Text("Sync your data across platforms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Authentication Form
            VStack(spacing: 20) {
                // Tab Selection
                HStack(spacing: 0) {
                    Button("Sign In") {
                        withAnimation {
                            isSignUp = false
                            error = nil
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSignUp ? Color.clear : Color.blue)
                    .foregroundColor(isSignUp ? .primary : .white)
                    .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                    
                    Button("Sign Up") {
                        withAnimation {
                            isSignUp = true
                            error = nil
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSignUp ? Color.blue : Color.clear)
                    .foregroundColor(isSignUp ? .white : .primary)
                    .cornerRadius(8, corners: [.topRight, .bottomRight])
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                // Form Fields
                VStack(spacing: 15) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.username)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                    
                    if isSignUp {
                        PasswordRequirementsView(password: $password)
                    }
                }
                
                // Error Message
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                // Primary Action Button
                Button(action: handlePrimaryAction) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle")
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading || !isFormValid)
                
                // Social Authentication
                VStack(spacing: 12) {
                    Text("Or continue with")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        // Apple Sign In
                        Button(action: signInWithApple) {
                            HStack {
                                Image(systemName: "applelogo")
                                Text("Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isLoading)
                        
                        // Google Sign In
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(minWidth: 400, minHeight: 600)
        .onAppear {
            authController.startListeningToAuthState()
        }
        .onChange(of: authController.authState) { 
            handleAuthStateChange($1)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && !username.isEmpty && password.count >= 8
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func handlePrimaryAction() {
        Task {
            await performAuthentication()
        }
    }
    
    private func performAuthentication() async {
        error = nil
        isLoading = true
        authAttemptCount += 1
        
        // For debugging
        print("Auth attempt #\(authAttemptCount): \(isSignUp ? "Sign Up" : "Sign In") started")
        
        do {
            if isSignUp {
                try await authController.signUpWithEmail(
                    email: email,
                    password: password,
                    username: username,
                    fullName: fullName
                )
                
                print("Sign up successful, auth state: \(authController.authState)")
                
                // Explicitly update app state
                await MainActor.run {
                    appState.setAuthenticated(true)
                }
            } else {
                try await authController.signInWithEmail(
                    email: email,
                    password: password
                )
                
                print("Sign in successful, auth state: \(authController.authState)")
                
                // Explicitly update app state
                await MainActor.run {
                    appState.setAuthenticated(true)
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                print("Auth error: \(error.localizedDescription)")
            }
        }
    }
    
    private func signInWithApple() {
        Task {
            do {
                try await authController.signInWith(provider: .apple)
                
                print("Apple sign-in successful, auth state: \(authController.authState)")
                
                // Explicitly update app state
                await MainActor.run {
                    appState.setAuthenticated(true)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    print("Apple sign-in error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        Task {
            // Call the Google sign-in method
            await authController.signInWithGoogleNative()
            
            print("Google sign-in attempted, auth state: \(authController.authState)")
            
            // Explicitly update app state if authenticated
            if authController.authState == .authenticated {
                await MainActor.run {
                    appState.setAuthenticated(true)
                }
            }
        }
    }
    
    private func handleAuthStateChange(_ newState: AuthState) {
        switch newState {
        case .authenticated:
            appState.setAuthenticated(true)
            isLoading = false
        case .notAuthenticated, .unauthenticated:
            appState.setAuthenticated(false)
            isLoading = false
        case .loading:
            appState.setLoading(true)
            isLoading = true
        case .undefined:
            break
        }
    }
}

// MARK: - Password Requirements View

struct PasswordRequirementsView: View {
    @Binding var password: String
    
    private var requirements: [(String, Bool)] {
        [
            ("At least 8 characters", password.count >= 8),
            ("Contains uppercase letter", password.rangeOfCharacter(from: .uppercaseLetters) != nil),
            ("Contains lowercase letter", password.rangeOfCharacter(from: .lowercaseLetters) != nil),
            ("Contains number", password.rangeOfCharacter(from: .decimalDigits) != nil)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password Requirements:")
                .font(.caption)
                .fontWeight(.semibold)
            
            ForEach(requirements, id: \.0) { requirement in
                HStack(spacing: 6) {
                    Image(systemName: requirement.1 ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(requirement.1 ? .green : .gray)
                        .font(.caption)
                    
                    Text(requirement.0)
                        .font(.caption)
                        .foregroundColor(requirement.1 ? .green : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight), radius: topRight, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight), radius: bottomRight, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft), radius: bottomLeft, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft), radius: topLeft, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()
        
        return path
    }
}
