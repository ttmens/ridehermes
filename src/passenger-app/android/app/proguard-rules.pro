# AMap SDK
-keep class com.amap.api.maps.** { *; }
-keep class com.amap.api.location.** { *; }
-keep class com.amap.api.services.** { *; }
-keep class com.amap.flutter.** { *; }

# Keep all model classes
-keepclassmembers class * extends com.amap.api.maps.model.** {
  <fields>;
  <methods>;
}

# Don't warn about missing classes from AMap
-dontwarn com.amap.api.maps.**
-dontwarn com.amap.api.location.**
-dontwarn com.amap.api.services.**
-dontwarn com.amap.flutter.**
