// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_hash.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactHashAdapter extends TypeAdapter<ContactHash> {
  @override
  final int typeId = 0;

  @override
  ContactHash read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContactHash(
      hash: fields[0] as String,
      name: fields[1] as String,
      phoneNumber: fields[2] as String?,
      lastSeen: fields[3] as DateTime,
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ContactHash obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.hash)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.lastSeen)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactHashAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
