# Kamera ve MLKit için kod küçültme sırasında silinmemesi gereken sınıflar
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class androidx.camera.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }

-dontwarn com.google.mlkit.**
-dontwarn androidx.camera.**
-dontwarn dev.steenbakker.mobile_scanner.**

# Genel Flutter/Play Core uyarılarını bastır
-dontwarn io.flutter.embedding.**