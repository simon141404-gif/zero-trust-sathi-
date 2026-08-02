# Sathi - Secure Cloud Storage / Smart Home UI Application

<p align="center">
  <img src="https://img.shields.io/badge/Zero--Trust-Architecture-blue" alt="Zero-Trust Architecture">
  <img src="https://img.shields.io/badge/Flutter-3.44+-purple" alt="Flutter">
  <img src="https://img.shields.io/badge/Node.js-18+-green" alt="Node.js">
</p>

A production-ready mobile application based on **Zero-Trust Architecture** ("Never Trust, Always Verify"). Sathi provides secure cloud storage and smart home control with enterprise-grade security features.

## 🛡️ Security Features

| Feature | Description |
|---------|-------------|
| **JWT Authentication** | Short-lived tokens (15 min) with refresh token rotation |
| **Rate Limiting** | 100 requests per 15 minutes per IP to prevent DDoS |
| **RBAC** | Role-Based Access Control (admin, user, guest) |
| **AES-256 Encryption** | Data-at-rest encryption with SHA-256 key derivation |
| **Root/Jailbreak Detection** | Native Android implementation to detect compromised devices |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Sathi Architecture                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐     ┌─────────────────────────────────┐   │
│  │   Flutter   │     │      Node.js Backend            │   │
│  │    Mobile   │────▶│      (Express.js)               │   │
│  │    App      │◀────│                                 │   │
│  └─────────────┘     └─────────────────────────────────┘   │
│         │                       │                          │
│         ▼                       ▼                          │
│  ┌─────────────┐     ┌─────────────────────────────────┐   │
│  │ AES-256     │     │ JWT Auth + Rate Limiter + RBAC │   │
│  │ Encryption  │     │                                 │   │
│  └─────────────┘     └─────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📱 Mobile App (Flutter)

### Features
- **Cloud Storage**: Upload, download, delete files with encryption
- **Smart Home**: Control lights, thermostats, locks
- **Security Alert**: Detects and warns about compromised devices

### Security Implementation
- **Root Detection**: Native Android code checks for:
  - Root apps (Magisk, SuperSU, etc.)
  - SU command availability
  - Dangerous system properties
  - Writable system paths
  - SELinux status
- **Encrypted Storage**: Hive boxes with AES-256 encryption
- **Secure Key Storage**: Flutter Secure Storage for tokens

### Dependencies
```yaml
dependencies:
  flutter_bloc: ^8.1.3    # State management
  dio: ^5.4.0             # HTTP client
  flutter_secure_storage: ^9.0.0  # Secure storage
  hive: ^2.2.3            # Local database
  encrypt: ^5.0.3         # AES encryption
  crypto: ^3.0.3          # SHA-256 hashing
```

## 🔐 Backend (Node.js)

### API Endpoints

| Endpoint | Method | Auth | Role |
|----------|--------|------|------|
| `/api/auth/login` | POST | No | - |
| `/api/auth/refresh` | POST | No | - |
| `/api/storage/files` | GET | Yes | user, admin |
| `/api/storage/upload` | POST | Yes | user, admin |
| `/api/storage/delete` | DELETE | Yes | user, admin |
| `/api/smarthome/devices` | GET | Yes | user, admin, guest |
| `/api/smarthome/control` | POST | Yes | user, admin |

### Security Middleware

```javascript
// JWT Authentication - 15 min expiry
const JWT_EXPIRY = '15m';

// Rate Limiting - 100 requests/15 min
const RATE_LIMIT_MAX_REQUESTS = 100;

// RBAC Roles
const ROLES = {
  ADMIN: 'admin',    // Full access
  USER: 'user',      // Read/write storage + smart home
  GUEST: 'guest'     // Read-only
};
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- Flutter 3.44+
- Android SDK

### Backend Setup
```bash
cd backend
npm install
npm start
# Server runs on port 3000
```

### Frontend Setup
```bash
cd sathi
flutter pub get
flutter run
```

### Build APK
```bash
cd sathi
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

## 📁 Project Structure

```
sathi-app/
├── README.md              # This file
├── SPEC.md                # Specification document
├── backend/               # Node.js Backend
│   ├── package.json
│   └── src/
│       ├── index.js
│       ├── middleware/
│       │   ├── auth.js       # JWT authentication
│       │   ├── rbac.js       # Role-based access control
│       │   └── rateLimiter.js # Rate limiting
│       └── routes/
│           ├── auth.js
│           ├── storage.js
│           └── smartHome.js
│
└── sathi/                # Flutter App
    ├── pubspec.yaml
    ├── android/           # Native Android code
    │   └── app/src/main/kotlin/.../MainActivity.kt  # Root detection
    └── lib/
        ├── core/
        │   ├── encryption/    # AES-256 encryption
        │   ├── security/     # Device security
        │   └── storage/     # Secure storage
        └── presentation/
            └── screens/     # UI screens
```

## 🔒 Security Best Practices

1. **Never trust, always verify** - Every request is authenticated
2. **Least privilege** - Users only get minimum required permissions
3. **Encrypt everything** - Data encrypted at rest and in transit
4. **Monitor & log** - All security events are logged
5. **Device integrity** - Compromised devices are rejected

## 📄 License

MIT License - See LICENSE file for details.

---

<p align="center">Built with ❤️ using Zero-Trust Architecture principles</p>
