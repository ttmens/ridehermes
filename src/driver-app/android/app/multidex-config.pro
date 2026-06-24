# Keep Flutter embedding classes in the primary dex.
# MainActivity extends FlutterActivity; if the superclass is in a secondary dex,
# ART may fail to load MainActivity on some devices.
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.ExclusiveAppComponent { *; }
-keep class io.flutter.embedding.android.FlutterActivityAndFragmentDelegate { *; }
-keep class io.flutter.embedding.android.FlutterActivityLaunchConfigs { *; }
