# Flutter embedding/plugins didaftarkan secara reflektif pada beberapa versi.
# Class aplikasi sendiri tidak di-keep agar nama implementasi keamanan dapat
# diminify/diobfuscate oleh R8.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
