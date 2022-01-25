// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walletconnectv2_flutter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMetadata _$AppMetadataFromJson(Map<String, dynamic> json) => AppMetadata(
      name: json['name'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String?,
      icons:
          (json['icons'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AppMetadataToJson(AppMetadata instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'url': instance.url,
      'icons': instance.icons,
    };

SessionPermissions _$SessionPermissionsFromJson(Map<String, dynamic> json) =>
    SessionPermissions(
      (json['blockchains'] as List<dynamic>).map((e) => e as String).toList(),
      (json['methods'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SessionPermissionsToJson(SessionPermissions instance) =>
    <String, dynamic>{
      'blockchains': instance.blockchains,
      'methods': instance.methods,
    };

JSONRpcRequest _$JSONRpcRequestFromJson(Map<String, dynamic> json) =>
    JSONRpcRequest(
      json['id'] as int,
      json['jsonrpc'] as String,
      json['method'] as String,
      json['params'] as List<dynamic>,
    );

Map<String, dynamic> _$JSONRpcRequestToJson(JSONRpcRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jsonrpc': instance.jsonrpc,
      'method': instance.method,
      'params': instance.params,
    };

SessionRequest _$SessionRequestFromJson(Map<String, dynamic> json) =>
    SessionRequest(
      json['topic'] as String,
      JSONRpcRequest.fromJson(json['request'] as Map<String, dynamic>),
      chainId: json['chainId'] as String?,
    );

Map<String, dynamic> _$SessionRequestToJson(SessionRequest instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'request': instance.request,
      'chainId': instance.chainId,
    };
