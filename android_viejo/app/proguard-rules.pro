# ==========================
# Google ML Kit (OCR / Text Recognition)
# ==========================
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ==========================
# Flutter
# ==========================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# ==========================
# SQLite / Room / Database
# ==========================
-keep class androidx.sqlite.** { *; }
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

# ==========================
# Kotlin Coroutines
# ==========================
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
