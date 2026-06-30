# CivicNexus — Flutter App

![Flutter](https://img.shields.io/badge/Flutter-3.32-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-8E44AD)
![Status](https://img.shields.io/badge/status-core%20complete-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**Mobile frontend for CivicNexus — the AI-powered civic issue reporting platform. Citizens photograph a problem; the app handles GPS capture, AI categorization, and real-time status, with no manual form-filling.**

⚙️ **Companion repo — Spring Boot backend:** [`civicnexus-backend`](https://github.com/awaneetdecoder/civicnexus-backend)

> **Architecture note.** This app talks to the full Spring Boot backend above. For the hackathon's mandatory live demo, the same Gemini-driven flow — photo analysis, severity scoring, map, community upvoting, gamified rewards — also ships as a Firebase-hosted web client, built to deploy reliably inside a hard deadline. **Live demo:** [civicnexus-94d0b.web.app](https://civicnexus-94d0b.web.app)

---

## Table of Contents
- [What This Does](#what-this-does)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Key Features](#key-features)
- [Running Locally](#running-locally)
- [API Integration Pattern](#api-integration-pattern)
- [How Frontend and Backend Connect](#how-frontend-and-backend-connect)
- [What's Built](#whats-built)
- [Roadmap](#roadmap)
- [Known Limitations](#known-limitations)
- [What This Project Demonstrates](#what-this-project-demonstrates)
- [Author](#author)

---

## What This Does

Citizens open the app, photograph a civic problem, tap submit. The app captures GPS coordinates automatically, sends the photo to the backend, and displays the Gemini AI analysis result — issue type, severity, responsible department, and coins earned — within 3–5 seconds. No manual categorization, no form-filling beyond an optional description.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.32, Dart 3.8 |
| State Management | Provider |
| HTTP | `dart:http` (multipart for image upload) |
| Storage | `flutter_secure_storage` (JWT token) |
| Location | `geolocator` + `geocoding` |
| Image | `image_picker` |
| Navigation | `page_transition` |
| Theme | Dynamic light/dark mode via `ThemeNotifier` |

## Project Structure

```
lib/
├── main.dart                    # App entry, theme setup, auth check on startup
├── auth_screen.dart             # Login with JWT
├── signup_screen.dart           # Registration
├── main_shell.dart              # Bottom nav shell
├── api_config.dart              # Single source of truth for all API endpoints
├── theme_notifier.dart          # Light/dark mode state
├── models/
│   ├── issue_model.dart         # Typed model for Issue API response
│   └── report_model.dart        # Legacy report model
├── screens/
│   ├── home_screen.dart         # Landing/dashboard
│   ├── reporter_screen.dart     # Photo + GPS + submit flow
│   ├── activity_screen.dart     # User's own reports
│   └── profile_screen.dart      # Coins, settings, dark mode toggle
├── services/
│   ├── gemini_service.dart      # Direct Gemini API call from Flutter
│   └── secure_storage_service.dart  # JWT save/read/delete
└── widget/
    ├── activity_list_item.dart  # Report card widget
    └── app_logo.dart            # Shared logo widget
```

## Key Features

**Automatic GPS capture.** Location fetches on button tap using `geolocator` with high accuracy. Coordinates are stored in state and sent with every report; `geocoding` reverse-resolves them to a readable address for display.

**Secure JWT storage.** After login, the token is stored using `flutter_secure_storage` — backed by Android Keystore on Android and Keychain on iOS. Every authenticated request reads this token and sends it in the `Authorization: Bearer` header.

**Multipart image upload.** Report submission uses `http.MultipartRequest` to send the image file alongside text fields (latitude, longitude, address, description) in a single HTTP request. The backend's `@RequestPart` and `@RequestParam` annotations receive them separately.

**Gemini analysis display.** On successful submission, a dialog shows the AI result — issue type, severity, responsible department, citizen advisory, and coins awarded — and resets the form on dismissal.

**Dynamic theme.** Light and dark themes are defined in `main.dart` via `ThemeData`. A `ThemeNotifier` (`ChangeNotifier`) stores the active mode and exposes a toggle; the profile screen's switch calls `toggleTheme()`, and the whole app re-renders through `Consumer<ThemeNotifier>`.

**Auto login check.** On startup, `main.dart` reads the stored JWT. If present and non-empty, the user lands directly on `MainShell`, skipping the login screen; otherwise they see `AuthScreen`. This runs inside a `FutureBuilder` with a loading spinner while the check completes.

## Running Locally

**Prerequisites:** Flutter 3.32+, Android Studio or VS Code with the Flutter extension, an Android emulator or physical device.

```bash
git clone https://github.com/awaneetdecoder/civicnexus-app
cd civicnexus-app
flutter pub get
```

Update `lib/api_config.dart`:
```dart
// For Android emulator
static const String _baseUrl = 'http://10.0.2.2:8080';

// For physical device (use your PC's local IP)
static const String _baseUrl = 'http://192.168.x.x:8080';

// For a deployed backend
static const String _baseUrl = 'https://civicnexus-backend.onrender.com';
```

```bash
flutter run
```

**Note:** Android 9+ blocks plain HTTP by default. For local development, `android/app/src/main/res/xml/network_security_config.xml` is configured to allow cleartext traffic to `10.0.2.2` and `localhost`.

## API Integration Pattern

Every screen that fetches data follows this exact pattern:

```dart
// 1. Declare future in state
Future<List<IssueModel>>? _issuesFuture;

// 2. Start fetch in initState
@override
void initState() {
  super.initState();
  _issuesFuture = _fetchIssues();
}

// 3. Use FutureBuilder in build
FutureBuilder<List<IssueModel>>(
  future: _issuesFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting)
      return CircularProgressIndicator();
    if (snapshot.hasError)
      return Text('Error: ${snapshot.error}');
    return ListView(children: snapshot.data!.map(...).toList());
  },
)
```

This pattern handles loading, error, and data states explicitly — no unhandled nulls.

## How Frontend and Backend Connect

```
Flutter                              Spring Boot
───────                              ───────────

1. User taps Login
   │
   ├── http.post(/api/auth/login)
   │   Body: {email, password} JSON
   │                                 JwtAuthFilter skips (public endpoint)
   │                                 AuthController.login()
   │                                 AuthService validates credentials
   │                                 JwtService.generateToken(user)
   │                                 Returns {token, name, email, coins}
   │
   ├── SecureStorageService.saveToken(token)
   └── Navigate to MainShell

2. User submits report
   │
   ├── http.MultipartRequest POST /api/issues
   │   Header: Authorization: Bearer <token>
   │   Fields: latitude, longitude, address
   │   File: image
   │                                 JwtAuthFilter intercepts
   │                                 Extracts token from header
   │                                 JwtService.extractEmail(token)
   │                                 UserRepository.findByEmail()
   │                                 Sets SecurityContext
   │                                 IssueController.submitIssue()
   │                                 @AuthenticationPrincipal User → current user
   │                                 IssueService.submitIssue()
   │                                   → saveImageLocally()
   │                                   → GeminiService.analyzeIssue()
   │                                   → issueRepository.save()
   │                                   → update user coins
   │                                 Returns IssueResponse JSON
   │
   └── Parse response → show success dialog with AI analysis
```

## What's Built

- [x] JWT auth — login, signup, auto-login check on startup
- [x] GPS auto-capture and reverse geocoding on the report flow
- [x] Multipart photo + GPS submission to the backend
- [x] Client-side Gemini pre-submission preview for instant feedback
- [x] Activity screen — user's own report history via the `FutureBuilder` pattern
- [x] Profile screen — coins, settings, dark mode toggle
- [x] Secure token storage via platform Keystore/Keychain

## Roadmap

- [ ] Issue map screen — `GET /api/issues/all` and `IssueModel` already exist on the backend side; the interactive map UI consuming them is the remaining piece
- [ ] Resolution flow UI for municipal workers, gated behind the backend's planned role-based access control
- [ ] Move the client-side Gemini call behind a backend proxy endpoint (see [Known Limitations](#known-limitations))
- [ ] Push notifications on issue status change (currently pull-based, refreshed on screen load)
- [ ] Widget and integration test suite

## Known Limitations

**Gemini API key is embedded in the client.** `gemini_service.dart` calls Gemini directly for a fast pre-submission preview, which means the key ships inside the compiled app and can be extracted by anyone who decompiles it. The backend's own server-side key — used for the authoritative analysis — is not exposed this way. The fix is straightforward: route the preview call through a lightweight backend proxy endpoint instead of calling Gemini from the client at all.

**No offline support.** Report submission requires an active connection; there's no local queueing for spotty connectivity, which matters for the field conditions this app is actually designed for.

## What This Project Demonstrates

- Building a complete mobile client against a real, self-built REST API — multipart uploads, JWT-secured requests, structured AI responses
- Secure credential handling using platform-native secure storage rather than shared preferences
- Disciplined async data loading — every fetch goes through an explicit loading/error/data state machine, not optimistic rendering
- Understanding of Android's network security model, not just working around an error message
- The ability to identify a project's own client-side security gap and describe the correct fix, rather than leaving it unexamined

## Author

**Awaneet Mishra**
[@awaneetdecoder](https://github.com/awaneetdecoder) · awaneet03991@gmail.com

## License

MIT — free to use for educational purposes.
