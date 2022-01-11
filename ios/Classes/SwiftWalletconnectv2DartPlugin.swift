import Flutter
import UIKit

public class SwiftWalletconnectv2DartPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "walletconnectv2_dart", binaryMessenger: registrar.messenger())
    let instance = SwiftWalletconnectv2DartPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
