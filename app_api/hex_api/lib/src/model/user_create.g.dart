// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCreate _$UserCreateFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['username', 'password', 'email'],
        );
        final val = UserCreate(
          username: $checkedConvert('username', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserCreateToJson(UserCreate instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'email': instance.email,
    };
