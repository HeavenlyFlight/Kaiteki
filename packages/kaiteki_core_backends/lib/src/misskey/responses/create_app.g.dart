// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAppResponse _$CreateAppResponseFromJson(Map<String, dynamic> json) =>
    CreateAppResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      callbackUrl: json['callbackUrl'] as String,
      permission: (json['permission'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      secret: json['secret'] as String,
    );

Map<String, dynamic> _$CreateAppResponseToJson(CreateAppResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'callbackUrl': instance.callbackUrl,
      'permission': instance.permission,
      'secret': instance.secret,
    };
