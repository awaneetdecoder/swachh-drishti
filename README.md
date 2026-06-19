# SwachhDrishti 🧹✨

### Citizen garbage reporting with AI-verified rewards

SwachhDrishti is a personal project — citizens photograph garbage in their area, and the backend classifies the garbage type and severity, then awards reward coins only if the photo is confirmed to actually contain garbage. Built solo, single role (citizen), no separate admin or web dashboard.

**Backend repo:** [swachh-drishti-backend](https://github.com/awaneetdecoder/swachh-drishti-backend)

---

## The idea

Most citizen complaint apps just collect reports with no way to prioritize them, and nothing stops someone from submitting a fake or empty photo to farm rewards. This project tries to solve both with one pipeline: every photo goes through Google Cloud Vision API's label detection, and the resulting labels drive both the severity ranking and the reward gate.

Google Cloud Vision API only returns raw labels (e.g. "waste", "plastic", "debris") with confidence scores — it does not natively classify garbage type or severity. That mapping is logic I wrote myself on top of the raw API output.

---

## How severity scoring actually works

1. Image saved with a UUID filename
2. Sent to Vision API → returns labels + confidence scores
3. My own mapping turns labels into a garbage type:
   - plastic / bottle / bag → **Plastic**
   - organic / food → **Organic**
   - electronic / circuit → **E-Waste**
   - anything else garbage-related → **Mixed**
4. My own mapping turns labels into a severity score (1–5):
   - litter → 1, debris → 2, garbage/pollution → 3, dump → 4, landfill → 5
   - adjusted up based on label count and confidence
5. Coins awarded by severity level: 5 / 10 / 20 / 35 / 50 for levels 1–5
6. **Reward gate:** coins are only awarded if a garbage-related label was actually detected in the photo — this is what blocks fake or empty submissions

---

## Features

- Photo + GPS report submission
- Garbage type and severity classification (logic above)
- AI-verified coin rewards
- Report status: Pending → In-Progress → Resolved (shown when app is opened, not pushed)
- JWT authentication, BCrypt password hashing

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart) |
| Backend | Spring Boot 3.5 (Java 17), Maven |
| Database | MySQL 8 with Spring Data JPA / Hibernate |
| Authentication | Spring Security + JWT, BCrypt |
| AI / computer vision | Google Cloud Vision API (Label Detection only) |
| Image handling | Multipart upload, local filesystem storage |
| Maps | Google Maps Flutter plugin (for hotspot view) |

This repo is the Flutter frontend only. Backend lives at [swachh-drishti-backend](https://github.com/awaneetdecoder/swachh-drishti-backend).

---

## Architecture at a glance

```
Citizen takes photo
        │
        ▼
Flutter app (GPS + image)
        │  multipart POST, JWT bearer token
        ▼
Spring Boot REST API
        │
        ├─► Google Cloud Vision API → raw labels + confidence
        ├─► My mapping logic → garbage type + severity score
        ├─► MySQL → report saved, coins awarded if verified
        └─► Response → severity, coins, status returned to app
```

---

## Getting started

### Prerequisites

- Flutter SDK (3.x or later)
- Android Studio or Xcode for emulator/device testing
- A running instance of the [SwachhDrishti backend](https://github.com/awaneetdecoder/swachh-drishti-backend) (Spring Boot + MySQL)

### Installation

```sh
git clone https://github.com/awaneetdecoder/swachh-drishti.git
cd swachh-drishti
flutter pub get
```

Open `lib/api_config.dart` and set the base URL:
```dart
static const String _baseUrl = 'http://10.0.2.2:8080'; // Android emulator
```

```sh
flutter run
```

> The backend must be running before the app can log in or submit reports.

---

## Project structure

```
lib/
├── main.dart
├── auth_screen.dart
├── signup_screen.dart
├── main_shell.dart              # Bottom nav: Home, Activity, Report, Profile
├── api_config.dart
├── theme_notifier.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── reporter_screen.dart     # Camera + GPS + report submission
│   ├── activity_screen.dart     # User's report history
│   └── profile_screen.dart
│
├── services/
│   └── secure_storage_service.dart   # JWT storage
│
├── models/
│   └── report_model.dart
│
└── widget/
    ├── app_logo.dart
    └── activity_list_item.dart
```

---

## Honest current limitations

- Solo personal project, not yet used or tested by anyone outside development.
- Hotspot map view is not built yet — clustering query exists on the backend, but there's no Flutter screen displaying it.
- Leaderboard is not built yet.
- Status updates are pull-based (shown on app open), not pushed.
- No automated test suite yet.
- Not deployed — runs locally against a local backend.

---

## Roadmap

- [x] JWT auth (signup/login)
- [x] Photo + GPS report submission
- [x] Severity classification + AI-verified rewards
- [ ] Hotspot map screen (Google Maps Flutter plugin, backend query already exists)
- [ ] Leaderboard screen
- [ ] Get a small group of real users to test it
- [ ] Push notifications on status change

---

## Author

**Awaneet Mishra**
- GitHub: [@awaneetdecoder](https://github.com/awaneetdecoder)
- Email: awaneet03991@gmail.com

---

## License

MIT — free to use for educational purposes.
