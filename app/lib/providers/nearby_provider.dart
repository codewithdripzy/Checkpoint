import 'package:flutter/material.dart';
import '../models/contact_hash.dart';

class NearbyProvider with ChangeNotifier {
  final List<ContactHash> _discoveredContacts = [];
  bool _isScanning = false;

  List<ContactHash> get discoveredContacts => List.unmodifiable(_discoveredContacts);
  bool get isScanning => _isScanning;

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void addFoundContact(ContactHash contact) {
    // Only add if not already in the list (based on hash)
    if (!_discoveredContacts.any((c) => c.hash == contact.hash)) {
      _discoveredContacts.insert(0, contact);
      notifyListeners();
    }
  }

  void clearDiscovered() {
    _discoveredContacts.clear();
    notifyListeners();
  }
}
