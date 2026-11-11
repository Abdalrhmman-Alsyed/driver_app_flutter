# Driver App — Flutter

A mobile app for delivery drivers who transfer shipments between branches. Drivers sign in, see their assigned trips, scan parcels and manage delivery manifests from their phone.

## Features

- **Secure sign-in** — tokens stored with `flutter_secure_storage`
- **Trips** — view and manage assigned trips between branches
- **Manifests** — load and unload shipments with delivery manifests
- **Parcels** — parcel details and status updates
- **Barcode & QR scanning** — scan parcels with the phone camera (`mobile_scanner`)
- **Vehicle info** — the driver's assigned vehicle
- **Branches** — organization units and facility network
- **Driver profile**
- **Sound feedback** on scans and a **keep-awake** mode during trips
- **Arabic localization** with right-to-left support

## Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter, Dart 3 |
| State management | flutter_bloc, equatable, provider |
| Navigation | go_router |
| Networking | dio (REST API) |
| Storage | flutter_secure_storage, shared_preferences |
| Device | mobile_scanner, audioplayers, wakelock_plus |

## Architecture

Feature-first structure, with each feature split into data and presentation layers:

```
lib/
├── app/          # app setup, routing, theme
├── core/         # networking, storage, shared widgets
├── features/
│   ├── auth/
│   ├── home/
│   ├── trips/
│   ├── manifests/
│   ├── parcels/
│   ├── vehicle/
│   ├── org_units/
│   ├── profile/
│   └── splash/
└── main.dart
```

## Getting Started

```bash
flutter pub get
flutter run
```

Requires Flutter with Dart SDK 3.6 or newer.

## Author

**Abdalrhmman Alsyed** — Full Stack Software Engineer
[LinkedIn](https://www.linkedin.com/in/abdalrhmman-alsyed-4a9691348) · [GitHub](https://github.com/Abdalrhmman-Alsyed)
