import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:walletconnectv2_dart/walletconnectv2_dart.dart';

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
    Walletconnectv2Dart.onProposal = _onProposal;
    Walletconnectv2Dart.onRequest = _onRequest;
    log("walletconectv2 ${Walletconnectv2Dart.onProposal}");
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      final res = await Walletconnectv2Dart.platformVersion;
      platformVersion = res.data!;
      final res2 = await Walletconnectv2Dart.init(
          AppMetadata(
              name: "Bitizen",
              description: "BitizenWallet",
              url: "https://bitizen.org",
              icons: [
                "https://bitizen.org/wp-content/uploads/2021/07/cropped-cropped-lALPBGnDc6ar_GfNBADNBAA_1024_1024.png_720x720g-192x192.jpg"
              ]),
          "xxxxxxxxxxxxx",
          true,
          'relay.walletconnect.com');
      log("walletconectv2 $res2");
      final res1 = await Walletconnectv2Dart.pair("wc:xxxxxxxxxxxxx");
      log("walletconectv2 $res1");
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

  Future<void> _onProposal(int proposalId, AppMetadata metadata,
      SessionPermissions permissions) async {
    log("walletconectv2 onProposal $proposalId ${metadata.toJson()} ${permissions.toJson()}");

    final List<String> accounts = [];

    for (var c in permissions.blockchains) {
      accounts.add("$c:0x0000000000000000000000000000000000000000");
      accounts.add("$c:0x0000000000000000000000000000000000000001");
    }

    final res = await Walletconnectv2Dart.approveProposal(proposalId, accounts);
    log("walletconectv2 onProposal res $res");
  }

  Future<void> _onRequest(AppMetadata metadata, SessionRequest request) async {
    if (request.request.method == "personal_sign") {
      Walletconnectv2Dart.response(request.topic, request.request.id,
          errCode: 1000, errMsg: "Failed demo");
    } else {
      Walletconnectv2Dart.response(request.topic, request.request.id,
          errCode: 0, data: "0x1000");
    }
  }
}
