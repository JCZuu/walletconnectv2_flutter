#import "Walletconnectv2FlutterPlugin.h"
#if __has_include(<walletconnectv2_flutter/walletconnectv2_flutter-Swift.h>)
#import <walletconnectv2_flutter/walletconnectv2_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "walletconnectv2_flutter-Swift.h"
#endif

@implementation Walletconnectv2FlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWalletconnectv2FlutterPlugin registerWithRegistrar:registrar];
}
@end
