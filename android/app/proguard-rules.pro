# Flutter framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore warnings across third-party dependencies during R8 shrinking
-dontwarn **
-ignorewarnings

# Provider & AndroidX Lifecycle
-keep class * extends androidx.lifecycle.ViewModel
-keep class * extends androidx.lifecycle.AndroidViewModel
-keep class * implements androidx.lifecycle.ViewModelProvider$Factory

# Sentry
-keepattributes LineNumberTable,SourceFile
-keep class io.sentry.** { *; }

# Hive
-keep class io.hive.** { *; }
-keep @io.hive.HiveType class *
-keepclassmembers class * {
  @io.hive.HiveField <fields>;
}

# JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Crypto/Encryption & Secure Storage
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Just Audio & Audio Players
-keep class com.ryanheise.just_audio.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# Location services
-keep class com.google.android.gms.location.** { *; }

# Media/Audio
-keep class android.media.** { *; }

# SQLite
-keep class * extends android.database.sqlite.** { *; }

# Keep Native Android Components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclasseswithmembernames class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

-keepclasseswithmembernames class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}