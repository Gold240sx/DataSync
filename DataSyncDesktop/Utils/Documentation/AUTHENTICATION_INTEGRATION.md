# Authentication Integration Guide

This document explains how authentication and session management have been integrated into the DataSync project.

## 🔐 **Authentication Architecture**

### **Core Components:**

#### **1. DesktopAuthController.swift** - Main Authentication Controller
- **Purpose**: Central authentication manager using Supabase Auth
- **Session Storage**: Uses `UserDefaultsLocalStorage` (UserDefaults-based) to avoid Keychain prompts
- **Authentication Methods**:
  - Email/Password sign-in and sign-up
  - Apple Sign-In (native)
  - Google Sign-In (native)
  - GitHub OAuth (web-based)
  - Password reset functionality

#### **2. AppState.swift** - Application State Management
- **Purpose**: Manages app-wide authentication state
- **Properties**:
  - `authState`: Current authentication state
  - `isLoggedIn`: Boolean authentication status
  - `showMainApp`: Controls main app visibility
  - `userProfile`: User profile data
  - `userAvatarURL`: User avatar URL
  - `isJWTExpired`: JWT expiration status

#### **3. AuthView.swift** - Authentication UI
- **Purpose**: Modern authentication interface
- **Features**: 
  - Tab-based UI (Login/Signup)
  - Form validation with real-time feedback
  - Social authentication buttons (Apple, Google)
  - Password requirements checklist
  - Error handling and loading states

### **Authentication Flow:**

```swift
// 1. App Initialization
DataSyncApp -> AppRootView -> AuthView (if not authenticated)

// 2. User Authentication
AuthView -> DesktopAuthController.signInWithEmail() 
        -> Supabase Auth API
        -> Session Creation

// 3. Session Storage
UserDefaultsLocalStorage stores session data locally
- Key prefix: "supabase_auth_"
- Stores: JWT tokens, user data, refresh tokens

// 4. State Management
DesktopAuthController.authState -> .authenticated
AppState.isLoggedIn -> true
AppState.showMainApp -> true

// 5. Profile Bootstrap
postAuthBootstrap() -> Creates user profile records
                   -> Ensures database rows exist
                   -> Sets up storage folders
```

## 📁 **File Structure**

```
DataSync/
├── Controllers/
│   └── DesktopAuthController.swift    # Main authentication controller
├── Models/
│   ├── AppState.swift                 # Application state management
│   └── DataSchema/
│       └── UsersSchema.swift          # User schema definitions
├── Views/
│   ├── AuthView.swift                 # Authentication UI
│   └── SupaLoginView.swift            # Legacy login view
├── DataSyncApp.swift                  # Main app with auth integration
└── AUTHENTICATION_INTEGRATION.md     # This documentation
```

## 🔧 **Key Features**

### **Session Management:**
- **Storage**: UserDefaults (not Keychain for simplicity)
- **Keys**: Prefixed with "supabase_auth_"
- **Data**: JWT tokens, user metadata, refresh tokens
- **Persistence**: Survives app restarts

### **Authentication States:**
```swift
enum AuthState {
    case undefined          // Initial state
    case authenticated      // User is signed in
    case unauthenticated    // User is signed out
    case notAuthenticated   // Alias for unauthenticated
    case loading           // Authentication in progress
}
```

### **User Profile Management:**
- **Public Data**: `users_public` table (username, avatar, signup source)
- **Private Data**: `users_private` table (email, sensitive info, auth provider)
- **API**: REST API with Supabase secret key for database operations

## 🗄️ **Database Schema Integration**

### **UsersPublicSchema** - Public User Data
```swift
TableSchema(
    tableName: "users_public",
    values: [
        TableValue(name: "id", dataType: "UUID", ...),
        TableValue(name: "username", dataType: "String", ...),
        TableValue(name: "display_name", dataType: "String", ...),
        TableValue(name: "avatar_url", dataType: "String", ...),
        TableValue(name: "created_at", dataType: "Date", ...),
        TableValue(name: "signup_source", dataType: "String", ...),
        TableValue(name: "is_verified", dataType: "Bool", ...)
    ],
    primaryKey: "id"
)
```

### **UsersPrivateSchema** - Private User Data
```swift
TableSchema(
    tableName: "users_private",
    values: [
        TableValue(name: "user_id", dataType: "UUID", ...),
        TableValue(name: "email", dataType: "String", encrypted: true, ...),
        TableValue(name: "phone_number", dataType: "String", encrypted: true, ...),
        TableValue(name: "preferences", dataType: "Data", encrypted: true, ...),
        TableValue(name: "last_login", dataType: "Date", ...),
        TableValue(name: "auth_provider", dataType: "String", ...),
        TableValue(name: "jwt_expires_at", dataType: "Date", ...)
    ],
    primaryKey: "user_id"
)
```

## 🚀 **Usage Examples**

### **Sign In with Email:**
```swift
try await DesktopAuthController.shared.signInWithEmail(
    email: "user@example.com",
    password: "password123"
)
```

### **Sign Up with Email:**
```swift
try await DesktopAuthController.shared.signUpWithEmail(
    email: "user@example.com",
    password: "password123",
    username: "username",
    fullName: "Full Name"
)
```

### **Social Authentication:**
```swift
// Apple Sign In
try await DesktopAuthController.shared.signInWith(provider: .apple)

// Google Sign In
try await DesktopAuthController.shared.signInWithGoogleNative()
```

### **Sign Out:**
```swift
await DesktopAuthController.shared.signOut()
```

## 🔒 **Security Features**

### **JWT Expiration Handling:**
```swift
@Published var isJWTExpired: Bool = false

// Detects JWT expiration from API responses
if httpResponse.statusCode == 401 && errorMsg.contains("JWT expired") {
    await MainActor.run {
        self.isJWTExpired = true
    }
}
```

### **Session Cleanup:**
```swift
func signOut() {
    // Clear local state immediately
    self.userProfile = nil
    self.userAvatarURL = nil
    self.authState = .notAuthenticated
    
    // Execute API sign-out
    try await authClientCopy.signOut()
}
```

## ⚙️ **Configuration**

### **Supabase Configuration:**
```swift
private static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL")
private static let supabasePublishableKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY")
private static let supabaseSecretKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SECRET_KEY")
```

### **Info.plist Requirements:**
```xml
<key>SUPABASE_URL</key>
<string>https://your-project.supabase.co</string>
<key>SUPABASE_PUBLISHABLE_KEY</key>
<string>your-publishable-key</string>
<key>SUPABASE_SECRET_KEY</key>
<string>your-secret-key</string>
```

## 🔄 **Session Flow Summary:**

1. **App Launch** → Check for existing session
2. **No Session** → Show AuthView
3. **User Authenticates** → Create session via Supabase
4. **Session Stored** → UserDefaults with "supabase_auth_" prefix
5. **Profile Bootstrap** → Create/update user records
6. **Main App** → Show authenticated interface
7. **Session Persistence** → Survives app restarts
8. **Sign Out** → Clear session and return to AuthView

## 🎯 **Integration Benefits:**

- ✅ **Seamless Authentication**: Modern UI with social login options
- ✅ **Session Persistence**: Survives app restarts
- ✅ **Security**: JWT expiration handling and encrypted storage
- ✅ **User Management**: Complete profile system with public/private data
- ✅ **Database Integration**: Automatic schema synchronization
- ✅ **Error Handling**: Comprehensive error states and user feedback
- ✅ **State Management**: Centralized app state with reactive updates

## 📚 **Related Files:**

- **Authentication Controller**: [`Controllers/DesktopAuthController.swift`](Controllers/DesktopAuthController.swift)
- **App State Management**: [`Models/AppState.swift`](Models/AppState.swift)
- **Authentication UI**: [`Views/AuthView.swift`](Views/AuthView.swift)
- **User Schemas**: [`Models/DataSchema/UsersSchema.swift`](Models/DataSchema/UsersSchema.swift)
- **Main App**: [`DataSyncApp.swift`](DataSyncApp.swift)
- **Adding Models Guide**: [`ADDING_MODELS.md`](ADDING_MODELS.md)

This authentication system provides a robust, secure foundation for the DataSync project with proper session management, user profile handling, and seamless integration with the existing data synchronization architecture.
