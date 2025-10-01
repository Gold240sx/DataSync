# AppState Schema Documentation

This document explains the AppState schema design that separates global online status data from local-only application state.

## 🎯 **Design Philosophy**

The AppState schema follows a **hybrid approach**:
- **Global Database**: Only minimal data needed to determine if users are online
- **Local Storage**: All sensitive and user-specific data stays in SwiftData only

## 📊 **Schema Structure**

### **Global App State (Synced to Cloud)**
**Table**: `app_state`  
**Purpose**: Minimal data for online status detection  
**Sync**: SwiftData ↔ CloudKit ↔ Supabase

```swift
struct AppStateSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "app_state",
        values: [
            TableValue(name: "user_id", dataType: "UUID", syncOptions: [.swiftData, .cloudKit, .supabase]),
            TableValue(name: "is_online", dataType: "Bool", syncOptions: [.swiftData, .cloudKit, .supabase]),
            TableValue(name: "last_seen", dataType: "Date", syncOptions: [.swiftData, .cloudKit, .supabase]),
            TableValue(name: "device_type", dataType: "String", syncOptions: [.swiftData, .cloudKit, .supabase]),
            TableValue(name: "app_version", dataType: "String", syncOptions: [.swiftData, .cloudKit, .supabase])
        ],
        primaryKey: "user_id"
    )
}
```

### **Local App State (SwiftData Only)**
**Table**: `local_app_state`  
**Purpose**: Sensitive user data and application state  
**Sync**: SwiftData only (never synced to cloud)

```swift
struct LocalAppStateSchema {
    static let schema: TableSchema = TableSchema(
        tableName: "local_app_state",
        values: [
            TableValue(name: "id", dataType: "UUID", syncOptions: [.swiftData]),
            TableValue(name: "auth_state", dataType: "String", syncOptions: [.swiftData]),
            TableValue(name: "user_profile", dataType: "Data", encrypted: true, syncOptions: [.swiftData]),
            TableValue(name: "session_token", dataType: "String", encrypted: true, syncOptions: [.swiftData]),
            TableValue(name: "refresh_token", dataType: "String", encrypted: true, syncOptions: [.swiftData]),
            // ... more local-only fields
        ],
        primaryKey: "id"
    )
}
```

## 🔐 **Data Classification**

### **Global Database Fields (Synced)**
| Field | Type | Purpose | Privacy |
|-------|------|---------|---------|
| `user_id` | UUID | Unique user identifier | Public |
| `is_online` | Bool | Current online status | Public |
| `last_seen` | Date | Last activity timestamp | Public |
| `device_type` | String | Device platform (macOS, iOS) | Public |
| `app_version` | String | Application version | Public |

### **Local Storage Fields (SwiftData Only)**
| Field | Type | Purpose | Privacy |
|-------|------|---------|---------|
| `auth_state` | String | Authentication status | Private |
| `user_profile` | Data | User profile data | Private (Encrypted) |
| `session_token` | String | JWT session token | Private (Encrypted) |
| `refresh_token` | String | Token refresh data | Private (Encrypted) |
| `preferences` | Data | User preferences | Private (Encrypted) |
| `is_jwt_expired` | Bool | JWT expiration status | Private |
| `offline_mode` | Bool | Offline operation mode | Private |

## 🚀 **Usage Examples**

### **Online Status Management**
```swift
// Update online status (syncs to global database)
OnlineStatusManager.shared.updateOnlineStatus(true)

// Start heartbeat to maintain online status
OnlineStatusManager.shared.startHeartbeat()

// Stop heartbeat and go offline
OnlineStatusManager.shared.stopHeartbeat()
```

### **Local State Management**
```swift
// Create local app state
let localState = LocalAppState(
    authState: "authenticated",
    userProfile: profileData,
    sessionToken: jwtToken,
    preferences: userPreferences
)

// Update local state
localState.authState = "loading"
localState.updatedAt = Date()
```

### **Global State Management**
```swift
// Create global app state
let globalState = GlobalAppState(
    userId: userID,
    isOnline: true,
    lastSeen: Date(),
    deviceType: "macOS",
    appVersion: "1.0.0"
)
```

## 🔄 **Sync Strategy**

### **Global App State Sync Flow**
```
SwiftData → CloudKit → Supabase
    ↑           ↓
Local DB ← Global DB
```

1. **Local Update**: User goes online/offline
2. **SwiftData**: Store in local `GlobalAppState` model
3. **CloudKit**: Sync to CloudKit database
4. **Supabase**: Sync to Supabase for cross-platform access
5. **Other Users**: Can see online status via global database

### **Local App State (No Sync)**
```
SwiftData Only
    ↑
Local DB
```

- **Never synced** to cloud services
- **Encrypted storage** for sensitive data
- **Local persistence** only

## 🛡️ **Security & Privacy**

### **Data Protection**
- **Encrypted Fields**: Session tokens, user profiles, preferences
- **Local Only**: Authentication state, JWT data, user preferences
- **Public Fields**: Only online status and basic device info

### **Privacy Benefits**
- **Minimal Exposure**: Only essential online status data is shared
- **User Control**: Sensitive data never leaves the device
- **Compliance**: Meets privacy requirements for user data

## 📱 **Cross-Platform Online Detection**

### **How Other Users See Online Status**
1. **User A** goes online → Updates `GlobalAppState.isOnline = true`
2. **CloudKit/Supabase** syncs the change
3. **User B** queries global database → Sees User A is online
4. **User B** can display online status in their app

### **Online Status Queries**
```swift
// Query online users
let onlineUsers = try context.fetch(
    FetchDescriptor<GlobalAppState>(
        predicate: #Predicate { $0.isOnline == true }
    )
)

// Check if specific user is online
let userOnline = try context.fetch(
    FetchDescriptor<GlobalAppState>(
        predicate: #Predicate { $0.userId == targetUserID && $0.isOnline == true }
    )
).first != nil
```

## 🎯 **Benefits of This Design**

### **Performance**
- ✅ **Minimal Sync**: Only essential data is synced
- ✅ **Fast Queries**: Online status queries are lightweight
- ✅ **Reduced Bandwidth**: Less data transfer

### **Privacy**
- ✅ **Data Minimization**: Only share what's necessary
- ✅ **Local Control**: Sensitive data stays on device
- ✅ **Encryption**: Sensitive fields are encrypted

### **Scalability**
- ✅ **Efficient Storage**: Minimal global database footprint
- ✅ **Fast Updates**: Online status updates are quick
- ✅ **Cross-Platform**: Works across all supported platforms

## 📁 **File Structure**

```
Models/
├── DataSchema/
│   └── AppStateSchema.swift          # Schema definitions
├── AppStateModels.swift              # SwiftData models
└── AppState.swift                    # Application state management
```

## 🔧 **Implementation Notes**

### **ModelContainer Configuration**
```swift
modelContainer = try ModelContainer(
    for: Project.self, GlobalAppState.self, LocalAppState.self,
    configurations: ModelConfiguration(
        schema: Schema([Project.self, GlobalAppState.self, LocalAppState.self]),
        isStoredInMemoryOnly: false
    )
)
```

### **Schema Registration**
```swift
lazy var allSchemas: [TableSchema] = [
    ProjectsSchema.schema,
    UsersPublicSchema.schema,
    UsersPrivateSchema.schema,
    AppStateSchema.schema,           // Global app state
    LocalAppStateSchema.schema       // Local app state
]
```

## 📚 **Related Documentation**

- **Authentication Integration**: [`AUTHENTICATION_INTEGRATION.md`](AUTHENTICATION_INTEGRATION.md)
- **Adding Models**: [`ADDING_MODELS.md`](ADDING_MODELS.md)
- **Schema Types**: [`Models/DataSchema/SchemaTypes.swift`](Models/DataSchema/SchemaTypes.swift)

This AppState schema design provides a secure, efficient way to manage online status while keeping sensitive user data local and private. 🚀
