import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:walletconnectv2_flutter/walletconnectv2_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    Walletconnectv2Flutter.onProposal = _onProposal;
    Walletconnectv2Flutter.onRequest = _onRequest;
    log("walletconectv2 ${Walletconnectv2Flutter.onProposal}");
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      final res = await Walletconnectv2Flutter.platformVersion;
      platformVersion = res.data!;
      final res2 = await Walletconnectv2Flutter.init(
          AppMetadata(
              name: "Bitizen",
              description: "BitizenWallet",
              url: "https://bitizen.org",
              icons: [
                "https://bitizen.org/wp-content/uploads/2021/07/cropped-cropped-lALPBGnDc6ar_GfNBADNBAA_1024_1024.png_720x720g-192x192.jpg"
              ]),
          "xxxxxxxxxxxx",
          true,
          'relay.walletconnect.com');
      log("walletconectv2 init successful $res2");
      final res1 = await Walletconnectv2Flutter.pair(
          "wc:xxxxxxxxxxxx@2?controller=false&publicKey=xxxxxxxxxxxx&relay=%7B%22protocol%22%3A%22waku%22%7D");
      log("walletconectv2 pair successful $res1");
    } catch (e) {
      platformVersion = 'Failed to get platform version. $e';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }

  Future<List<String>> _onProposal(
      AppMetadata metadata, SessionPermissions permissions) async {
    log("walletconectv2 onProposal ${metadata.toJson()} ${permissions.toJson()}");

    final List<String> accounts = [];

    for (var c in permissions.blockchains) {
      accounts.add("$c:0x0000000000000000000000000000000000000000");
      accounts.add("$c:0x0000000000000000000000000000000000000001");
    }

    // throw "test error";

    return accounts;
  }

  Future<String> _onRequest(
      AppMetadata metadata, SessionRequest request) async {
    if (request.request.method == "personal_sign") {
      throw "Failed demo";
    } else {
      return "0x0";
    }
  }
}
