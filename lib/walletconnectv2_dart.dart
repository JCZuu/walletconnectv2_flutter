
import 'dart:async';

import 'package:flutter/services.dart';

class Walletconnectv2Dart {
  static const MethodChannel _channel = MethodChannel('walletconnectv2_dart');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
