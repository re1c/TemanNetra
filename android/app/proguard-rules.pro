# Flutter Core Engine Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Protect Generated Code and Serialization Models (Riverpod, JSON)
-keepattributes *Annotation*,EnclosingMethod,InnerClasses,Signature
-dontwarn json_annotation.**

# Firebase & Firestore Reflection Protections
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Cryptographic and Encoding Network Channel Keep Rules (Supabase/Postgrest)
-keepattributes Signature,InnerClasses,EnclosingMethod
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Ignore Play Store Split Install components (Fixes Flutter R8 Dynamic Feature Linker Error)
-dontwarn com.google.android.play.core.**
