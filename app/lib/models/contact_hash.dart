import 'package:hive/hive.dart';

part 'contact_hash.g.dart';

@HiveType(typeId: 0)
class ContactHash extends HiveObject {
  @HiveField(0)
  final String hash;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? phoneNumber; // Optional, for local reference

  @HiveField(3)
  final DateTime lastSeen;

  @HiveField(4)
  final double? latitude;
  
  @HiveField(5)
  final double? longitude;

  ContactHash({
    required this.hash,
    required this.name,
    this.phoneNumber,
    required this.lastSeen,
    this.latitude,
    this.longitude,
  });
}
