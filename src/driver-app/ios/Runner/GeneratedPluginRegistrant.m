//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<amap_flutter_location/AMapFlutterLocationPlugin.h>)
#import <amap_flutter_location/AMapFlutterLocationPlugin.h>
#else
@import amap_flutter_location;
#endif

#if __has_include(<amap_flutter_map/AMapFlutterMapPlugin.h>)
#import <amap_flutter_map/AMapFlutterMapPlugin.h>
#else
@import amap_flutter_map;
#endif

#if __has_include(<flutter_secure_storage/FlutterSecureStoragePlugin.h>)
#import <flutter_secure_storage/FlutterSecureStoragePlugin.h>
#else
@import flutter_secure_storage;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AMapFlutterLocationPlugin registerWithRegistrar:[registry registrarForPlugin:@"AMapFlutterLocationPlugin"]];
  [AMapFlutterMapPlugin registerWithRegistrar:[registry registrarForPlugin:@"AMapFlutterMapPlugin"]];
  [FlutterSecureStoragePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSecureStoragePlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
