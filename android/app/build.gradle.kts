import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Play Store'a yüklenecek release imzalama anahtarı, `android/key.properties`
// dosyasından okunur (git'e KOMİTLENMEZ — bkz. .gitignore). Bu dosya yoksa
// (henüz gerçek bir keystore kurulmadıysa) release build eskisi gibi debug
// anahtarıyla imzalanmaya devam eder, böylece CI/lokal derleme bozulmaz —
// sadece Play Store'a yüklenemez.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Gerçek bir release keystore kurulduysa onunla, kurulmadıysa
            // (henüz Play Store'a yüklenmeyecekse) debug anahtarıyla imzala.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

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
            // Android, isShrinkResources=true iken isMinifyEnabled=false
            // olmasına izin vermiyor ("Removing unused resources requires
            // unused code shrinking to be turned on") — Flutter'ın eklentisi
            // bunu da varsayılan olarak true yaptığından ikisini birlikte
            // kapatmak gerekiyor.
            isShrinkResources = false
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
