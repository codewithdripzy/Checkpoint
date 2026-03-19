# 🛰️ Checkpoint: Decentralized Proximity Network

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.27-02569B?logo=flutter)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Alpha-orange.svg)]()

> A cutting-edge, offline-first ecosystem for device tracking and contact discovery using Peer-to-Peer (P2P) and Peer-to-Checkpoint (P2C) mesh networking.

---

## 🌌 The Vision

Checkpoint is an open-source project designed to bridge the gap between digital identity and physical proximity. By utilizing device radio (Bluetooth Low Energy) and a global network of low-power "Checkpointers," we enable users to find lost devices and discover known contacts in their vicinity—**all without requiring an internet connection.**

## 🛠️ Integrated Modules

### 📱 Checkpoint Mobile (Flutter App)
The primary user interface. Designed with a premium, high-fidelity dark aesthetic.
- **Offline Contact Discovery**: Detects known contacts passing by using SHA-256 hashed identifiers.
- **Radar Dashboard**: A real-time visual pulse showing nearby anonymous nodes and identified friends.
- **Privacy-First**: No personal data (phone numbers, names) is ever broadcast in plain text.

### 📡 Checkpointers (Hardware Layer)
Distributed nodes acting as fixed location pointers.
- **Global Mesh**: Strategically placed devices providing GPS and local data to passing users.
- **Autonomous Power**: Designed for solar and kinetic energy harvesting.

## 🏗️ Architecture & Security

Checkpoint operates on a decentralized trust model:
1. **Hashing**: Each user’s identifier (phone number/email) is salted and hashed locally.
2. **Advertising**: Devices broadcast a unique Service UUID and their hashed ID.
3. **Collision Detection**: Nearby devices compare received hashes against local "Known Contact" buckets.
4. **Encryption**: All P2P data exchanges are encrypted to prevent eavesdropping in public spaces.

## 🚀 Getting Started

To dive into the mobile implementation:

```bash
cd app
flutter pub get
flutter run
```

*For more details, see the [App README](app/README.md).*

## 🛣️ Roadmap

- [x] BLE Proximity Prototype (Mobile)
- [x] Secure Contact Hashing Engine
- [ ] P2C Hardware Protocol Definition
- [ ] End-to-End Encrypted Messaging (Offline)
- [ ] AI-Powered Movement Prediction

## 🤝 Contributing

We welcome thinkers, tinkerers, and builders. Check out our [Contributing Guide](CONTRIBUTING.md) to get started.

---

<p align="center">
  Built with ❤️ by the Checkpoint Community.
</p>
