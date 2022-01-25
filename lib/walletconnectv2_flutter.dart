import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

part 'walletconnectv2_flutter.g.dart';

@JsonSerializable()
class AppMetadata {
  String? name;
  String? description;
  String? url;
  List<String>? icons;

  AppMetadata({this.name, this.description, this.url, this.icons});

  factory AppMetadata.fromJson(Map<String, dynamic> json) =>
      _$AppMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AppMetadataToJson(this);
}

@JsonSerializable()
class SessionPermissions {
  List<String> blockchains;
  List<String> methods;

  SessionPermissions(this.blockchains, this.methods);

  factory SessionPermissions.fromJson(Map<String, dynamic> json) =>
      _$SessionPermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$SessionPermissionsToJson(this);
}

@JsonSerializable()
class JSONRpcRequest {
  int id;
  String jsonrpc;
  String method;
  dynamic params;

  JSONRpcRequest(this.id, this.jsonrpc, this.method, this.params);

  factory JSONRpcRequest.fromJson(Map<String, dynamic> json) =>
      _$JSONRpcRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JSONRpcRequestToJson(this);
}

@JsonSerializable()
class SessionRequest {
  String topic;
  JSONRpcRequest request;
  String? chainId;

  SessionRequest(this.topic, this.request, {this.chainId});

  factory SessionRequest.fromJson(Map<String, dynamic> json) =>
      _$SessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SessionRequestToJson(this);
}

class Result<T> {
  bool success;
  String? msg;
  T? data;

  Result(this.success, this.msg, this.data);

  @override
  String toString() {
    return "success: $success, msg: $msg, data: $data";
  }
}

class Walletconnectv2Flutter {
  static const MethodChannel _channel =
      MethodChannel('walletconnectv2_flutter');

  static Future<void> Function(
          int proposalId, AppMetadata metadata, SessionPermissions permissions)?
      onProposal;
  static Future<void> Function(AppMetadata metadata, SessionRequest request)?
      onRequest;

  static Future<Result<String?>> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return Result(true, null, version);
  }

  static Future<Result<T>> _parseError<T>(Future<T> fut) async {
    log("walletconectv2  call native $fut");
    try {
      final args = await fut;
      return Result(true, null, args);
    } on MissingPluginException {
      return Result(false, "没有实现对应的方法", null);
    } on PlatformException catch (error) {
      return Result(false, error.message, error.details);
    } catch (error) {
      return Result(false, error.toString(), null);
    }
  }

  static Future<Result<void>> init(AppMetadata metadata, String projectId,
      bool isController, String relayHost) async {
    _channel.setMethodCallHandler(_methodCallHandler);
    return _parseError<void>(_channel.invokeMethod('init', {
      "metadata": jsonEncode(metadata),
      "projectId": projectId,
      "isController": isController,
      "relayHost": relayHost,
    }));
  }

  static Future<Result<void>> pair(String uri) async {
    return _parseError<void>(_channel.invokeMethod('pair', uri));
  }

  static Future<Result<void>> approveProposal(
      int proposalId, List<String> accounts) async {
    log("walletconectv2 proposalId $proposalId accounts $accounts");
    return _parseError<void>(_channel.invokeMethod('approveProposal', {
      "proposalId": proposalId,
      "accounts": accounts,
    }));
  }

  static Future<Result<void>> response(String topic, int id,
      {String? data, int? errCode, String? errMsg}) async {
    log("walletconectv2 topic $topic requestId $id data $data errCode $errCode errMsg $errMsg");
    return _parseError<void>(_channel.invokeMethod('response', {
      "topic": topic,
      "id": id,
      "data": data,
      "err_code": errCode,
      "err_msg": errMsg,
    }));
  }

  static Future<dynamic> _methodCallHandler(MethodCall call) async {
    log("walletconectv2 ${call.method} ${call.arguments.runtimeType} ${call.arguments} $onProposal");
    try {
      switch (call.method) {
        case "onProposal":
          final proposalId = call.arguments["proposalId"] as int;
          final AppMetadata proposer = AppMetadata.fromJson(
              jsonDecode(call.arguments["proposer"] as String));
          final SessionPermissions permissions = SessionPermissions.fromJson({
            "blockchains": call.arguments["permissions"]["blockchains"],
            "methods": call.arguments["permissions"]["methods"],
          });
          if (onProposal != null) {
            onProposal!(proposalId, proposer, permissions);
          }
          return;
        case "onRequest":
          final AppMetadata proposer = AppMetadata.fromJson(
              jsonDecode(call.arguments["proposer"] as String));
          final SessionRequest request = SessionRequest.fromJson(
              jsonDecode(call.arguments["request"] as String));
          if (onRequest != null) {
            onRequest!(proposer, request);
          }
          return;
      }
    } catch (e) {
      log("walletconectv2 error: $e");
    }
  }
}