import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing — credentials live in android/key.properties (gitignored).
// See android/key.properties.example for the template and the keytool command.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Whether this invocation is actually building a release artifact. The
// buildTypes { release } closure is evaluated during configuration on EVERY
// Gradle invocation (including `flutter run` debug builds), so we only enforce
// the keystore requirement when a release task is on the command line.
val isReleaseBuildRequested = gradle.startParameter.taskNames.any { name ->
    val task = name.substringAfterLast(':')
    task.startsWith("assembleRelease") ||
        task.startsWith("bundleRelease") ||
        task.startsWith("installRelease")
}

android {
    namespace = "com.tander.tander_flutter_v3"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tander.app"
        // Phase 5 mobile calling minimum: API 26 (Android 8.0).
        // Twilio Android Video SDK supports 25+; we pin 26 for
        // - mandatory notification channels (API 26+)
        // - cleaner foreground-service lifecycle from Oreo
        // - alignment with master plan rev 2 §22
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
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
            // Release MUST be signed with the upload keystore. Fail loudly
            // rather than silently shipping a debug-signed (unpublishable)
            // artifact. Pass -PallowDebugRelease=true for an explicit
            // debug-signed local/perf build without a keystore.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else if (project.hasProperty("allowDebugRelease") ||
                !isReleaseBuildRequested) {
                // Debug builds (and explicit -PallowDebugRelease) fall back to
                // debug signing; this branch never produces a published artifact.
                signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Release build requires android/key.properties. " +
                        "Generate an upload keystore (see " +
                        "android/key.properties.example) or pass " +
                        "-PallowDebugRelease=true for an explicit debug-signed build."
                )
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Phase 5 — Twilio Programmable Video Android SDK.
    // Wraps WebRTC with Twilio room/SFU semantics. Required for the v2
    // call path. Replaces flutter_webrtc usage in mobile call_manager
    // (legacy P2P stack retires in Stage 5).
    implementation("com.twilio:video-android:7.10.4")
}

flutter {
    source = "../.."
}
