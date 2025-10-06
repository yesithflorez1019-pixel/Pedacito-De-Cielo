# Flutter's default rules.
-dontwarn io.flutter.embedding.**
# End of Flutter's default rules.



# Mantiene las clases de Firebase y Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }


-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.protobuf.** { *; }
-keep class io.grpc.** { *; }
-keep class com.squareup.okhttp.** { *; }
-dontwarn okio.**
-dontwarn io.grpc.netty.**
-keepclassmembers,allowshrinking,allowobfuscation class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
}