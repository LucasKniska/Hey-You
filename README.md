# Hey You

**An app built for human connection.**

Hey You is a Flutter mobile app that turns online matching into real-world meetups. Instead of endless in-app chatting, Hey You connects you with compatible people nearby and gets you meeting in person — right now or on a schedule you agree on together.

📺 **Watch the demo:** [YouTube Short](https://www.youtube.com/shorts/esVyvlAr6Ao)

> Screenshots coming soon — see the video above for a walkthrough of the app in action.

## How It Works

1. **Create Your Profile** — Sign up and set up your profile with your interests, personality, and what you're looking to connect about.
2. **Discover People Nearby** — A personality quiz and location-based search surface people in your area who share your interests.
3. **Form Connections in Real Life** — Meet up right away with live map directions, or let Hey You automatically plan a scheduled meetup.

## Features

- **Nearby Matching** — Find and connect with users near your current location using live geolocation.
- **Personality Quiz** — A multi-batch quiz used to match you with compatible people, kept private and never shown publicly.
- **Meet Now** — Real-time matching with a live Google Map showing walking directions and distance to your match.
- **Scheduled Meetups** — Automatically plan a meeting time and place when meeting right away isn't an option.
- **Match Notifications & Splash Screens** — Animated feedback (connected, rejected, match-complete) so every match feels alive.
- **Previous Connections** — Review past matches and reach back out to people you've already connected with.
- **Leaderboards** — Track total matches, current streak, and longest streak against other nearby users.
- **Profile & Stats** — Manage your bio, character traits, and connection stats from your profile page.
- **Firebase Auth** — Email/password sign-in and sign-up plus Google Sign-In, with email verification and password recovery.

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart, SDK ^3.7.0)
- **State Management:** [GetX](https://pub.dev/packages/get) (`get`, `get_storage`)
- **Backend:** [Firebase](https://firebase.google.com/) (`firebase_auth`, `cloud_firestore`, `firebase_core`, Google Sign-In)
- **Maps & Location:** `google_maps_flutter`, `flutter_map`, `geolocator`, `geocoding`, `latlong2`
- **Routing/Directions:** [OpenRouteService](https://openrouteservice.org/) API for walking directions between matched users
- **UI/Animation:** `flutter_animate`, `animate_do`, `smooth_page_indicator`, `blur`, `iconsax_flutter`

## Project Structure

```
lib/
├── Common/            # Shared widgets, navigation, location services
├── Data/
│   ├── models/         # Data models (matches, users, leaderboard, quiz, etc.)
│   └── repositories/    # Authentication, matching, and user repositories
├── Features/
│   ├── Authentication/  # Onboarding, sign in/up, email verification
│   ├── EditProfile/     # Profile page and controller
│   ├── Leaderboards/    # Leaderboard tabs and rankings
│   ├── Match/            # Meet Now, matching, splash screens, scheduled meetups
│   ├── Onboarding/       # App onboarding and terms of service
│   ├── PersonalityQuiz/  # Personality/interest quiz
│   └── ViewConnections/  # Previous connections history
└── utils/              # Constants, theming, formatters, validators, helpers
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK ^3.7.0)
- A configured Firebase project (see `lib/firebase_options.dart`)
- A Google Maps API key for `google_maps_flutter`

### Setup

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Platforms

This project is configured to run on Android, iOS, web, Windows, macOS, and Linux.
