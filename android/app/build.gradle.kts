import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Dati della chiave di firma, letti da android/key.properties (escluso da git)
val proprietaChiave = Properties()
val fileChiave = rootProject.file("key.properties")
if (fileChiave.exists()) {
    proprietaChiave.load(FileInputStream(fileChiave))
}

android {
    namespace = "it.univpm.arrocco.flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Diverso dall'app Kotlin (it.univpm.arrocco): le due app possono stare sullo stesso dispositivo
        applicationId = "it.univpm.arrocco.flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = proprietaChiave["keyAlias"] as String?
            keyPassword = proprietaChiave["keyPassword"] as String?
            storeFile = (proprietaChiave["storeFile"] as String?)?.let { file(it) }
            storePassword = proprietaChiave["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Firma con la stessa chiave dell'app Kotlin; senza key.properties si usa quella di debug
            signingConfig = if (fileChiave.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
