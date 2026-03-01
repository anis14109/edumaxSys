This codebase contain flutter app named- `edumaxsys` & laravel project named- `laravel-server`. 

Subject: Build a Full-Stack Laravel Jetstream & Flutter Offline-First System.
Task: Develop a dual-platform system (Web + Mobile) with the following specifications:

1. Backend (Laravel 12 + Jetstream + Livewire)
Auth: Install Laravel Jetstream with the Livewire stack. Enable API support (Sanctum) and Profile Photos.

Login UI: Customize the default login page with a Modern Glassmorphism effect & background dark overlay image. Use Tailwind CSS for a frosted-glass card, a vibrant mesh-gradient background, and crisp typography. Use multi language support & custom font support as Bangla language for SolaimanLipi font & English language for Barlow font

Dashboard: Create a modern, responsive dashboard with a sidebar layout & Metarialize theme style. Include User Profile with User info Edit, Password change, Photo pic Update. A CRUD resource for "Users" (which will sync with Flutter).

API: Secure the backend with Laravel Sanctum. Create protected API endpoints for GET, POST, PUT, and DELETE on the "Users" resource. Ensure all responses are JSON.

2. Mobile (Flutter + Offline-First)
State Management: Use Riverpod for clean architecture.
Local database: sqflite
Local Persistence: Implement Custom build Auto Sync to create an offline-first experience. As a reference- PowerSync or Hive/Drift are the best example. Use similar functionality like PowerSync does. The app must allow users to view, create, and edit "Users" without internet. 

Sync Logic:
Use Dio for API calls.
Implement a Repository Pattern that reads from the local DB first.
Implement a background sync service that pushes pending local changes to the Laravel API and pulls new updates when the device is back online. Always auto Check for server update every 1 hours.

Auth Flow: A mobile login screen that authenticates via the Laravel Sanctum /api/login endpoint and stores the Bearer token securely.

3. Code Requirements
Provide the complete Tailwind CSS code for the Glassmorphism login.
Provide the Laravel Controller and API Routes.
Provide the Flutter Data Model and the Sync Service logic.
Add detailed comments to explain the synchronization and authentication handshake.

4. Create Enrich README.md file with Folder structure, App Wrokflow, Installation guide etc