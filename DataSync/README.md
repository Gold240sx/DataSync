# DataSync Desktop

A macOS application that demonstrates data synchronization between SwiftData, CloudKit, and Supabase, with support for encrypted data storage.

## Features

- User authentication with Supabase (email/password, Google Sign-In)
- SwiftData local storage with CloudKit sync
- Secure data storage with encryption for sensitive information
- Cross-platform data synchronization
- User profile management

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Supabase account
- Google Cloud Platform account (for Google Sign-In)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/DataSync.git
cd DataSync
```

### 2. Environment Configuration

Create a `.env` file in the project root based on the `.env.example` template:

```bash
cp .env.example .env
```

Edit the `.env` file and fill in your credentials:

```
# Development credentials
DEV_PASSWORD=your_dev_password_here
DEV_USER_ID=your_dev_user_id_here

# Google Sign-In
GID_CLIENT_ID=your_google_client_id_here
GOOGLE_URL_SCHEME=com.googleusercontent.apps.your_client_id_here

# Supabase configuration
SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key_here
SUPABASE_SECRET_KEY=your_supabase_secret_key_here
SUPABASE_URL=https://your-project-id.supabase.co
```

### 3. Info.plist Configuration

Update the `Info.plist` file with your environment variables. The template uses variable substitution that needs to be configured in your Xcode project.

### 4. Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Set up authentication providers (Email, Google)
3. Run the SQL scripts in the `Utils/Data/SchemaToSQL.swift` file to create the necessary database schema and RLS policies

### 5. Google Sign-In Setup

1. Create a project in the [Google Cloud Console](https://console.cloud.google.com/)
2. Configure the OAuth consent screen
3. Create OAuth 2.0 client IDs for macOS
4. Add the client ID to your `.env` file

### 6. Build and Run

Open the project in Xcode:

```bash
open DataSync.xcodeproj
```

Build and run the application.

## Architecture

- **Models**: SwiftData models with CloudKit and Supabase sync attributes
- **Views**: SwiftUI views for the user interface
- **Controllers**: Authentication and data synchronization logic
- **Utils**: Helper functions and extensions

## Database Schema

The application uses a set of tables for storing user data and projects:

- `users_public`: Public user information
- `users_private`: Private user information (encrypted)
- `projects`: User projects with metadata

## Security

- Sensitive data is encrypted before storage
- Row Level Security (RLS) policies protect data in Supabase
- Authentication tokens are securely stored in the keychain

## License

[MIT License](LICENSE)

## Contact

For questions or support, please open an issue on the GitHub repository.