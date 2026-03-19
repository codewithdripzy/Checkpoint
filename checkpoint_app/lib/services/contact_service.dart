import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact_hash.dart';

class ContactService {
  static const String boxName = 'hashed_contacts';

  static Future<void> syncContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return;

    final contacts = await FastContacts.getAllContacts();
    final box = await Hive.openBox<ContactHash>(boxName);

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        final normalizedPhone = _normalizePhone(phone.number);
        final hash = _generateHash(normalizedPhone);

        // Store the hash with the contact name
        final entry = ContactHash(
          hash: hash,
          name: contact.displayName,
          phoneNumber: normalizedPhone,
          lastSeen: DateTime.now(),
        );

        // Use the hash as the key for fast lookup
        await box.put(hash, entry);
      }
    }
  }

  static String _normalizePhone(String phone) {
    // Remove non-numeric characters except leading plus
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static String _generateHash(String phone) {
    // Note: In production, we'd add a salt and more robust normalization
    final bytes = utf8.encode(phone);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<ContactHash?> findContactByHash(String hash) async {
    final box = await Hive.openBox<ContactHash>(boxName);
    return box.get(hash);
  }
}
