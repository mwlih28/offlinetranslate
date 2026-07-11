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

// google_mlkit_translation (com.google.mlkit:translate:17.0.3) pins old
// versions of Google Play Services' shared/foundational libraries.
// Android 14+ devices have been observed failing model downloads with
// "NullPointerException: getClass() on a null object reference" — a
// known signature of Play Services' reflection-based Task/receiver code
// breaking on newer Android versions (see googlesamples/mlkit#744, an
// unresolved Android 14 broadcast-receiver-flag issue). These shared
// libraries get patched independently of the mlkit:translate artifact
// itself (unchanged since Aug 2024), so we force newer versions here.
configurations.all {
    resolutionStrategy {
        force(
            "com.google.android.gms:play-services-basement:18.10.0",
            "com.google.android.gms:play-services-base:18.10.0",
            "com.google.android.gms:play-services-tasks:18.4.1",
        )
    }
}
