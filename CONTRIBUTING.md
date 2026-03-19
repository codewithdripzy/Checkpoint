# Contributing to Checkpoint 🛰️

First of all, thank you for considering contributing to Checkpoint! We’re building a decentralized, offline-first proximity network, and we need thinkers and tinkerers like you.

## 📋 Code of Conduct

Help us keep Checkpoint a welcoming place for everyone. Be respectful, inclusive, and collaborative.

## 🛠️ Getting Started

### 📱 Setting up the Mobile App
1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/check-point-org/checkpoint.git
    cd app
    ```
2.  **Install Flutter**: Ensure you have the latest stable [Flutter SDK](https://flutter.dev/docs/get-started/install/macos).
3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Generate Adapters**:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## 🛠️ Our Tech Stack
-   **App**: Flutter (Dart)
-   **Storage**: Hive (Local NoSQL)
-   **Radio**: Bluetooth Low Energy (BLE)
-   **Security**: SHA-256 (Crypto)

## 🤝 How Can I Contribute?

### 🪲 Reporting Bugs
-   Check the existing issues to see if it’s already been reported.
-   Be as descriptive as possible. Include:
    -   Your OS and Flutter version.
    -   Device model (for BLE issues).
    -   Steps to reproduce.

### ✨ Suggesting Features
-   Open a new issue with a clear description of the feature and how it fits into the project vision.

### 👩‍💻 Pull Requests
1.  **Fork the repo** and create your branch from `main`.
2.  **Lint your code**: Run `flutter analyze` to ensure no warnings or errors.
3.  **Write clear commit messages**:
    -   `feat: add offline messaging service`
    -   `fix: resolve BLE timeout on Android 12`
    -   `docs: update readme with build steps`
4.  **Open the PR** and describe your changes.

## 🎨 Code Standards
-   **Style**: We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
-   **Theme**: All new UI components must use the `AppTheme` constants in `lib/utils/app_theme.dart`.
-   **Privacy**: Never broadcast raw identifiers. Always hash before transmission.

## 📬 Contact
-   Reach out on GitHub Issues or join our community Discord (coming soon).

---

Thank you for building a decentralized future with us! 🚀
