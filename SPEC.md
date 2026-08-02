# Sathi - Secure Cloud Storage / Smart Home UI Application

## Project Overview
- **Project Name**: Sathi
- **Type**: Mobile Application (Flutter) with Backend API (Node.js)
- **Core Functionality**: Secure cloud storage and smart home control application based on Zero-Trust Architecture principles ("Never Trust, Always Verify")

## Architecture

### Backend (Node.js)
- **Framework**: Express.js
- **Port**: 3000

#### Security Features
1. **JWT Authentication**
   - Short-lived tokens (15 minutes)
   - Refresh token rotation
   - Secure token storage

2. **Rate Limiting**
   - In-memory rate limiter
   - 100 requests per 15 minutes per IP

3. **Role-Based Access Control (RBAC)**
   - Three roles: admin, user, guest
   - Protected endpoints with role-based authorization

### Frontend (Flutter)
- **Target**: Android/iOS Mobile Application

#### Security Features
1. **Device Security**
   - Root/Jailbreak detection via MethodChannel
   - Session termination on compromised devices
   
2. **Data-at-Rest Encryption**
   - AES-256 encryption using encrypt package
   - Key derivation using SHA-256
   - Hive for secure local storage

3. **Secure Storage**
   - Encrypted Hive boxes
   - Secure token storage

## UI Screens

1. **Login Screen**
   - Secure authentication form
   - JWT token management

2. **Cloud Storage Screen**
   - File listing with icons
   - Upload/Delete operations
   - File metadata display

3. **Smart Home Screen**
   - Device listing with status
   - Toggle controls for lights, thermostats
   - Lock controls for smart locks

4. **Security Alert Screen**
   - Displayed when device is compromised
   - Clear security warning message

## Project Structure

```
sathi-app/
├── SPEC.md                    # This specification
├── backend/                   # Node.js Backend
│   ├── package.json
│   └── src/
│       ├── index.js          # Entry point
│       ├── middleware/
│       │   ├── auth.js       # JWT authentication
│       │   ├── rbac.js       # Role-based access control
│       │   └── rateLimiter.js # Rate limiting
│       ├── routes/
│       │   ├── auth.js       # Auth endpoints
│       │   ├── storage.js    # Storage endpoints
│       │   └── smartHome.js  # Smart home endpoints
│       └── services/
│           └── tokenService.js
│
└── sathi/                    # Flutter App
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── di/
        │   │   └── injection.dart
        │   ├── encryption/
        │   │   └── encryption_service.dart
        │   ├── network/
        │   │   └── api_client.dart
        │   ├── security/
        │   │   └── device_security_service.dart
        │   └── storage/
        │       └── secure_storage_service.dart
        └── presentation/
            ├── bloc/
            │   ├── auth_bloc.dart
            │   └── auth_event.dart
            └── screens/
                ├── login_screen.dart
                ├── security_alert_screen.dart
                ├── smart_home_screen.dart
                └── storage_screen.dart
```

## Security Best Practices Implemented

1. ✅ JWT with short expiry times
2. ✅ Rate limiting to prevent DDoS
3. ✅ RBAC middleware for endpoints
4. ✅ Device integrity verification (root/jailbreak detection)
5. ✅ Data-at-rest AES-256 encryption
6. ✅ Secure token storage
7. ✅ Environment variable handling for secrets
8. ✅ HTTPS-only communication (production)

## Build Output

- **Debug APK**: `sathi/build/app/outputs/flutter-apk/app-debug.apk`
- **Size**: ~155 MB (debug build with all dependencies)
