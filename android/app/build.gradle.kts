plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.offlinetranslate.offlinetranslate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.offlinetranslate.offlinetranslate"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // KRİTİK: Flutter'ın kendi Gradle eklentisi (FlutterPlugin.kt),
            // release build type için isMinifyEnabled'ı VARSAYILAN OLARAK
            // true yapıyor — bu, bu dosyada hiçbir yerde görünmez çünkü
            // eklenti tarafında ayarlanır. R8, özel "keep" kuralları
            // olmadan google_mlkit_translation/Play Hizmetleri'nin
            // reflection tabanlı iç sınıflarını yeniden adlandırıp kod
            // yolunu bozuyor; bu da gerçek cihazlarda model indirirken
            // "NullPointerException: getClass() on null object" hatasına
            // yol açıyordu (native stack trace'te r8-map-id ile obfuske
            // edilmiş sınıf adları görülerek doğrulandı). Bu satır
            // Flutter'ın varsayılanını ezip minifikasyonu tamamen kapatır.
            isMinifyEnabled = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
