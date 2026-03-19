# 📱 Checkpoint Mobile App

> The core user interface for the Checkpoint decentralised proximity network. Built with **Flutter** for a premium, cross-platform experience.

[![Flutter](https://img.shields.io/badge/Flutter-3.27-02569B?logo=flutter)](https://flutter.dev)
[![Hive](https://img.shields.io/badge/Storage-Hive-FFD700?logo=hive)](https://pub.dev/packages/hive)
[![BLE](https://img.shields.io/badge/Radio-BLE-0275d8?logo=bluetooth)](https://pub.dev/packages/flutter_blue_plus)

---

## ✨ Key Features

- **P2P Offline Discovery**: Detect other Checkpoint users in your vicinity without an active internet connection.
- **Secure Matching Engine**: Automatically identifies if a nearby device belongs to one of your contacts using local SHA-256 hash matching.
- **High-Fidelity Dashboard**: Interactive, animated radar interface designed with a premium dark mode and glassmorphism.
- **Sync & Secure**: Local contact hashing on first run ensures raw phone numbers never leave your device.

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Radio (BLE)**: [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus) & [Flutter BLE Peripheral](https://pub.dev/packages/flutter_ble_peripheral)
- **Local Persistence**: [Hive](https://pub.dev/packages/hive) (NoSQL)
- **Contacts**: [Fast Contacts](https://pub.dev/packages/fast_contacts)
- **Security**: [Crypto](https://pub.dev/packages/crypto) (SHA-256)

## 📁 System Architecture

```text
lib/
├── models/         # Data models and Hive adapters
├── providers/      # UI state management (Nearby discovery state)
├── services/       # Core business logic (BLE, Contacts, Hashing)
├── screens/        # Premium high-fidelity UI screens
├── widgets/        # Reusable UI components (Animated Radar, etc.)
└── utils/          # Theming (ThemeData) and shared constants
```

## 🚀 Installation & Build

### Prerequisites
- Flutter SDK (stable channel)
- A physical Android/iOS device (BLE features are limited on simulators)

### Setup Steps
1. Navigate to the `app` directory:
   ```bash
   cd app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Hive Adapters:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Build and Run:
   ```bash
   flutter run
   ```

## 🔒 Privacy & Security

Checkpoint prioritizes user privacy above all else:
- **No Internet Required**: All proximity discovery happens over local radio.
- **Hashing**: Contact identifiers are hashed with SHA-256. Raw identifiers are never broadcast.
- **Local Database**: All matched contact information is stored locally using Hive. No data is sent to central servers.

## 👥 Contributing

Please refer to the root [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on how to submit pull requests and report bugs.

---

<p align="center">
  <b>Designed with precision. Built for decentralisation.</b>
</p>
