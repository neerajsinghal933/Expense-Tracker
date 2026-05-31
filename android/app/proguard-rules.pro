# Pulse Money - ProGuard Rules for Production Release
# Keeps Flutter and Dart runtime classes while obfuscating app code

# Flutter and Dart runtime
-keep class io.flutter.** { *; }
-keep class com.google.android.material.** { *; }
-keep class androidx.** { *; }

# Keep Parcelable classes
-keep class * implements android.os.Parcelable { *; }

# Keep database classes (SQLite/Drift)
-keep class * extends io.objectbox.** { *; }
-keep interface * { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep share_plus
-keep class com.builttoroam.** { *; }

# Keep serializable classes
-keep class java.io.Serializable { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom annotations
-keepattributes *Annotation*

# Keep line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable

# Optimize
-optimizationpasses 5
-dontusemixedcaseclassnames

# Configuration for resource shrinking
-dontwarn androidx.**
-dontwarn com.google.android.**
-dontwarn io.flutter.**

