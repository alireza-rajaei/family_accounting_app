# Keep Flutter entry points and plugin registrants
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep classes and members annotated with @Keep
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * { @androidx.annotation.Keep *; }

# Keep enums and parcelables
-keepclassmembers enum * { *; }
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Common libraries used by plugins
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.google.gson.**
-dontwarn com.squareup.moshi.**

# Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep runtime annotations
-keepattributes *Annotation*

