# Adding New Models to DataSync

This guide explains how to add new SwiftData models to the DataSync project, including where to create schema files and what files need to be updated.

## 📁 Project Structure

``` bash
Models/
├── DataSchema/           # Schema definitions and registry
│   ├── DataSchema.swift      # Main schema registry (delegates to SchemaHelpers)
│   ├── SchemaHelpers.swift   # Core schema operations and helper methods
│   ├── SchemaTypes.swift     # Data types and enums (DataSyncOption, CloudKitContainer, etc.)
│   ├── ProjectsSchema.swift  # Project schema definition
│   └── UsersSchema.swift     # User schemas (public and private)
├── Project.swift         # SwiftData model for projects
└── [YourModel].swift     # Your new SwiftData model
```

## 🔧 Step-by-Step Process

### 1. Create the SwiftData Model

Create your model file in the `Models/` directory:

**File**: `Models/[YourModel].swift`

```swift
//
//  [YourModel].swift
//  DataSync
//
//  Created by [Your Name] on [Date].
//

import Foundation
import SwiftData

@Model
final class [YourModel]: Codable {
    var id: UUID
    var name: String
    var description: String?
    var createdAt: Date
    var updatedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, createdAt, updatedAt
    }
}
```

### 2. Create Schema Definition

Create a new schema file in the `Models/DataSchema/` directory:

**File**: `Models/DataSchema/[YourModel]Schema.swift`

```swift
//
//  [YourModel]Schema.swift
//  DataSync
//
//  Created by [Your Name] on [Date].
//

import Foundation

struct [YourModel]Schema {
    static let schema: TableSchema = TableSchema(
        tableName: "[your_model_table]",
        values: [
            TableValue(
                name: "id",
                dataType: "UUID",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase],
                unique: true
            ),
            TableValue(
                name: "name",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "description",
                dataType: "String",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "created_at",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            ),
            TableValue(
                name: "updated_at",
                dataType: "Date",
                encrypted: false,
                syncOptions: [.swiftData, .cloudKit, .supabase]
            )
        ],
        primaryKey: "id"
    )
}
```

### 3. Update Schema Registry

**File**: `Models/DataSchema/SchemaHelpers.swift`

Add your schema to the `allSchemas` array:

```swift
// Get all schemas
lazy var allSchemas: [TableSchema] = [
    ProjectsSchema.schema,
    UsersPublicSchema.schema,
    UsersPrivateSchema.schema,
    [YourModel]Schema.schema  // ← Add this line
]
```

### 4. Update DataSyncApp.swift (if needed)

**File**: `DataSyncApp.swift`

If your model needs to be included in the SwiftData model container, add it to the `modelContainer`:

```swift
import SwiftData

@main
struct DataSyncApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Project.self, 
                [YourModel].self,  // ← Add your model here
                configurations: ModelConfiguration(
                    schema: Schema([Project.self, [YourModel].self]),
                    isStoredInMemoryOnly: false
                )
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

## 📋 Required Files to Update

When adding a new model, you must update these files:

1. **Create**: `Models/[YourModel].swift` - Your SwiftData model
2. **Create**: `Models/DataSchema/[YourModel]Schema.swift` - Schema definition
3. **Update**: `Models/DataSchema/SchemaHelpers.swift` - Add to `allSchemas` array
4. **Update**: `DataSyncApp.swift` - Add to model container (if needed)

## 🔗 Direct File Links

- **Schema Registry**: [`Models/DataSchema/SchemaHelpers.swift`](Models/DataSchema/SchemaHelpers.swift)
- **Data Schema Types**: [`Models/DataSchema/SchemaTypes.swift`](Models/DataSchema/SchemaTypes.swift)
- **Example Project Model**: [`Models/Project.swift`](Models/Project.swift)
- **Example Project Schema**: [`Models/DataSchema/ProjectsSchema.swift`](Models/DataSchema/ProjectsSchema.swift)
- **Example User Schemas**: [`Models/DataSchema/UsersSchema.swift`](Models/DataSchema/UsersSchema.swift)
- **App Configuration**: [`DataSyncApp.swift`](DataSyncApp.swift)

## 🎯 Schema Configuration Options

### Data Types

- `"UUID"` - For unique identifiers
- `"String"` - For text fields
- `"Date"` - For timestamps
- `"Data"` - For binary data (images, files)
- `"Int"` - For numbers
- `"Bool"` - For boolean values

### Sync Options

- `[.swiftData]` - Local SwiftData only
- `[.cloudKit]` - CloudKit sync
- `[.supabase]` - Supabase sync
- `[.swiftData, .cloudKit, .supabase]` - All platforms

### Encryption

- `encrypted: false` - Plain text storage
- `encrypted: true` - Encrypted storage (for sensitive data)

### CloudKit Containers

- `[.public]` - Public CloudKit database
- `[.private]` - Private CloudKit database
- `[.shared]` - Shared CloudKit database

## ✅ Checklist

- [ ] Created SwiftData model with proper `@Model` annotation
- [ ] Implemented `Codable` protocol with proper `init(from decoder:)` and `encode(to:)` methods
- [ ] Created schema definition file in `Models/DataSchema/`
- [ ] Added schema to `SchemaHelpers.allSchemas` array
- [ ] Updated `DataSyncApp.swift` model container (if needed)
- [ ] Tested model creation and data persistence
- [ ] Verified schema registry includes your model

## 🚨 Common Pitfalls

1. **Missing Codable Implementation**: Always implement both `init(from decoder:)` and `encode(to:)` methods
2. **Forgetting Schema Registration**: Don't forget to add your schema to `SchemaHelpers.allSchemas`
3. **Incorrect Data Types**: Match schema data types with Swift model property types
4. **Missing Model Container**: Add your model to the `ModelContainer` in `DataSyncApp.swift`

## 📚 Examples

See these files for reference implementations:

- **Project Model**
  
  [`Models/Project.swift`](Models/Project.swift)
- **User Models**: [`Models/DataSchema/UsersSchema.swift`](Models/DataSchema/UsersSchema.swift)
- **Project Schema**: [`Models/DataSchema/ProjectsSchema.swift`](Models/DataSchema/ProjectsSchema.swift)
