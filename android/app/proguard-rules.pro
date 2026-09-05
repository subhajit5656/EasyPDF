# ProGuard / R8 Rules for Firebase & Google Sign-In Release Builds
-keepattributes *Annotation*
-keepclassmembers class * {
    @org.webkit.provider.* <methods>;
}
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
