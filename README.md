# EduMax System - Full-Stack Laravel & Flutter Offline-First Application

A dual-platform (Web + Mobile) educational administration system built with Laravel 12 (Jetstream + Livewire) for the backend and Flutter with offline-first architecture for the mobile app.

## Project Structure

```
edumaxSys/
├── laravel-server/          # Laravel 12 Backend
│   ├── app/
│   │   ├── Http/
│   │   │   └── Controllers/
│   │   │       ├── Api/
│   │   │       │   ├── AuthController.php    # API Authentication
│   │   │       │   └── UserController.php    # User CRUD API
│   │   │       └── LanguageController.php    # Multi-language
│   │   └── Models/
│   │       └── User.php                      # User Model with Sanctum
│   ├── config/
│   │   └── sanctum.php                       # Sanctum Configuration
│   ├── resources/
│   │   └── views/
│   │       ├── auth/
│   │       │   └── login.blade.php           # Glassmorphism Login
│   │       └── layouts/
│   │           └── guest.blade.php           # Guest Layout
│   └── routes/
│       ├── api.php                           # API Routes
│       └── web.php                           # Web Routes
│
└── edumaxsys/                # Flutter Mobile App
    ├── lib/
    │   ├── core/
    │   │   ├── constants/
    │   │   │   └── api_constants.dart        # API & DB Constants
    │   │   └── services/
    │   │       ├── api_service.dart          # Dio HTTP Client
    │   │       ├── database_service.dart    # SQLite Database
    │   │       └── sync_service.dart        # Offline-First Sync
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── user.dart                # User Model
    │   │   │   └── pending_sync.dart        # Sync Queue Model
    │   │   └── repositories/
    │   │       └── user_repository.dart     # Repository Pattern
    │   ├── presentation/
    │   │   ├── providers/
    │   │   │   └── auth_provider.dart       # Riverpod Providers
    │   │   └── screens/
    │   │       ├── auth/
    │   │       │   └── login_screen.dart    # Mobile Login
    │   │       ├── home/
    │   │       │   └── home_screen.dart    # Dashboard
    │   │       └── users/
    │   │           └── users_screen.dart    # User CRUD
    │   └── main.dart                        # App Entry Point
    └── pubspec.yaml
```

## Features

### Backend (Laravel 12 + Jetstream + Livewire)

1. **Authentication**
   - Laravel Jetstream with Livewire stack
   - Laravel Sanctum for API token authentication
   - Profile photos support

2. **Glassmorphism Login UI**
   - Modern frosted-glass card design
   - Vibrant mesh-gradient background with dark overlay
   - Animated floating shapes
   - Crisp typography

3. **Multi-language Support**
   - English (Barlow font)
   - Bangla (SolaimanLipi font)
   - Language switcher on login page

4. **Dashboard**
   - Modern sidebar layout
   - Materialize theme style
   - User profile with edit, password change, photo update

5. **RESTful API**
   - Sanctum-protected endpoints
   - Full CRUD for Users resource
   - JSON responses

### Mobile (Flutter + Offline-First)

1. **State Management**
   - Riverpod for clean architecture
   - Repository pattern implementation

2. **Local Database**
   - sqflite for local persistence
   - Automatic sync queue management

3. **Offline-First Sync (PowerSync-like)**
   - Read from local DB first
   - Background sync service
   - Push pending changes when online
   - Pull server updates when online
   - Auto-check for updates every hour

4. **Authentication Flow**
   - Mobile login via Laravel Sanctum /api/login
   - Bearer token stored securely

## Installation Guide

### Prerequisites

- PHP 8.2+
- Composer
- Node.js 18+
- Flutter SDK 3.11+
- MySQL/MariaDB

### Backend Setup

```bash
# Navigate to Laravel directory
cd laravel-server

# Install dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure database in .env
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=edumaxsys
# DB_USERNAME=root
# DB_PASSWORD=

# Run migrations
php artisan migrate

# Install Jetstream
php artisan jetstream:install livewire

# Configure Sanctum in .env
# SANCTUM_STATEFUL_DOMAINS=localhost,localhost:3000,127.0.0.1,127.0.0.1:8000
# SESSION_DOMAIN=localhost

# Publish Sanctum config
php artisan vendor:publish --provider="Laravel\Sanctum\ServiceProvider"

# Install Node dependencies
npm install

# Build assets
npm run build

# Start development server
php artisan serve
```

### Mobile Setup

```bash
# Navigate to Flutter directory
cd edumaxsys

# Get dependencies
flutter pub get

# Update API base URL in lib/core/constants/api_constants.dart
# static const String baseUrl = 'http://10.0.2.2:8000/api';

# Run the app
flutter run
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/login` | User login |
| POST | `/api/register` | User registration |
| POST | `/api/logout` | User logout |

### User Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/user` | Get current user |
| PUT | `/api/user/profile` | Update profile |
| PUT | `/api/user/password` | Change password |
| POST | `/api/user/photo` | Upload photo |

### Users CRUD
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users` | List users |
| POST | `/api/users` | Create user |
| GET | `/api/users/{id}` | Get user |
| PUT | `/api/users/{id}` | Update user |
| DELETE | `/api/users/{id}` | Delete user |

## App Workflow

### Authentication Flow

1. User opens mobile app
2. App checks for stored token in flutter_secure_storage
3. If authenticated, show Home Screen; otherwise, show Login
4. User enters credentials
5. App sends POST to `/api/login` with email/password
6. On success, receive Bearer token
7. Store token securely
8. Navigate to Home Screen

### Offline-First Sync Flow

1. **Local First**: All read operations query SQLite first
2. **Queue Changes**: Create/Update/Delete operations are queued locally
3. **Auto-Sync**: Every hour, check for pending changes
4. **Push**: When online, push queued changes to server
5. **Pull**: After push, pull latest data from server
6. **Conflict Resolution**: Server wins for conflicts on synced records

### Data Model Sync Fields

```dart
class User {
  final int? id;              // Server ID
  final String name;
  final String email;
  final String? password;
  
  // Offline-first sync fields
  final int syncStatus;       // 0=pending, 1=synced, 2=failed
  final String? localId;      // Local UUID
  final DateTime? lastSyncedAt;
}
```

## Key Files Explained

### Sync Service (`sync_service.dart`)

The sync service implements the PowerSync-like functionality:

1. **Push Changes**: Processes pending sync queue, sends CREATE/UPDATE/DELETE to API
2. **Pull Changes**: Fetches latest server data, updates local DB
3. **Conflict Resolution**: Local pending changes take precedence over server
4. **Auto-Sync**: Timer-based background sync every hour

### Authentication Handshake

```
Mobile App                    Laravel Backend
    |                              |
    |--- POST /api/login --------->|
    |     {email, password}        |
    |<-- {user, token} ------------|
    |                              |
    |  Store token securely       |
    |                              |
    |--- GET /api/users --------->|
    |     Bearer: {token}         |
    |<-- {users[]} ---------------|
    |                              |
```

## Technology Stack

### Backend
- Laravel 12
- Jetstream (Livewire)
- Sanctum
- Tailwind CSS

### Mobile
- Flutter 3.11+
- Riverpod (State Management)
- sqflite (Local Database)
- Dio (HTTP Client)
- flutter_secure_storage (Token Storage)

## License

MIT License
