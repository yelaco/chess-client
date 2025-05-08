// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 3;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      username: fields[1] as String,
      locate: fields[2] as String,
      picture: fields[3] as String,
      rating: fields[4] as double,
      membership: fields[5] as Membership,
      createAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.locate)
      ..writeByte(3)
      ..write(obj.picture)
      ..writeByte(4)
      ..write(obj.rating)
      ..writeByte(5)
      ..write(obj.membership)
      ..writeByte(6)
      ..write(obj.createAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MembershipAdapter extends TypeAdapter<Membership> {
  @override
  final int typeId = 2;

  @override
  Membership read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Membership.guest;
      case 1:
        return Membership.premium;
      default:
        return Membership.guest;
    }
  }

  @override
  void write(BinaryWriter writer, Membership obj) {
    switch (obj) {
      case Membership.guest:
        writer.writeByte(0);
        break;
      case Membership.premium:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
