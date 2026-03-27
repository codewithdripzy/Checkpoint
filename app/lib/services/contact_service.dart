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
    // 1. Keep only digits
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 2. Handle Nigerian leading 0 (replace with 234)
    if (digits.startsWith('0') && digits.length == 11) {
      digits = '234${digits.substring(1)}';
    }
    
    // 3. Ensure no '+' remains (already handled by digit regex, but for clarity)
    return digits;
  }

  static String generateHash(String phone) {
    // Public wrapper for sharing
    return _generateHash(_normalizePhone(phone));
  }

  static String _generateHash(String phone) {
    final bytes = utf8.encode(phone);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> saveMyNumber(String phone) async {
    final box = await Hive.openBox('profile');
    final hash = generateHash(phone);
    await box.put('my_hash', hash);
    await box.put('my_phone', _normalizePhone(phone));
  }

  static Future<String?> getMyHash() async {
    final box = await Hive.openBox('profile');
    return box.get('my_hash');
  }

  static Future<Box<ContactHash>> getHashedContactsBox() async {
    return await Hive.openBox<ContactHash>(boxName);
  }

  static Future<ContactHash?> findContactByHash(String hash) async {
    final box = await getHashedContactsBox();
    return box.get(hash);
  }
}
