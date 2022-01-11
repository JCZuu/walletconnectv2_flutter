#import "Walletconnectv2DartPlugin.h"
#if __has_include(<walletconnectv2_dart/walletconnectv2_dart-Swift.h>)
#import <walletconnectv2_dart/walletconnectv2_dart-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "walletconnectv2_dart-Swift.h"
#endif

@implementation Walletconnectv2DartPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWalletconnectv2DartPlugin registerWithRegistrar:registrar];
}
@end
