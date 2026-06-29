import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")   // Firebase Crashlytics
}

// ── Versioning ────────────────────────────────────────────────────────────────
// versionCode  : auto-derived from pubspec version build number (e.g. 3.3.0+4 → 4)
//                Increment the build number in pubspec.yaml for every Play Store upload.
// versionName  : human-readable string from pubspec (e.g. "3.3.0")
// Rule: NEVER manually edit versionCode here. Always bump pubspec.yaml version.
// ─────────────────────────────────────────────────────────────────────────────

// ── Signing ───────────────────────────────────────────────────────────────────
// Priority order:
//   1. Environment variables (CI/GitHub Actions) — KEYSTORE_BASE64 decoded at build time
//   2. key.properties file (local developer machine)
//   3. Debug signing fallback (never used for production)
// ─────────────────────────────────────────────────────────────────────────────
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.mmmarket.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"  // Required by Firebase/Facebook plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.mmmarket.app"
        minSdk = 23  // Required by flutter_secure_storage
        targetSdk = flutter.targetSdkVersion

        // Dynamic versioning — driven entirely by pubspec.yaml
        // To release a new version: bump `version: X.Y.Z+N` in pubspec.yaml
        // where N is the versionCode (must always increase for Play Store).
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Note: buildConfigField requires buildFeatures.buildConfig = true
        // Crashlytics is always enabled in release builds via bootstrap.dart
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                // Local developer machine: use key.properties
                keyAlias     = keyProperties["keyAlias"]     as String
                keyPassword  = keyProperties["keyPassword"]  as String
                storeFile    = file(keyProperties["storeFile"] as String)
                storePassword= keyProperties["storePassword"] as String
            } else {
                // CI/GitHub Actions: key.properties is written by workflow from secrets
                // The workflow decodes KEYSTORE_BASE64 → mm_market_prod.jks
                // and writes key.properties before this block is evaluated.
                // This else branch is only a safety fallback.
                val ksFile = file("mm_market_prod.jks")
                if (ksFile.exists()) {
                    keyAlias      = System.getenv("KEYSTORE_KEY_ALIAS")     ?: "mm_market_prod"
                    keyPassword   = System.getenv("KEYSTORE_KEY_PASSWORD")  ?: ""
                    storeFile     = ksFile
                    storePassword = System.getenv("KEYSTORE_STORE_PASSWORD") ?: ""
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists() ||
                                file("mm_market_prod.jks").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 shrinking + resource shrinking
            isMinifyEnabled    = true
            isShrinkResources  = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Upload Crashlytics mapping file to Firebase for deobfuscated stack traces
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                mappingFileUploadEnabled = true
                nativeSymbolUploadEnabled = false
            }
        }
        debug {
            isMinifyEnabled   = false
            isShrinkResources = false
            // Disable Crashlytics in debug builds to avoid polluting production dashboard
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                mappingFileUploadEnabled = false
            }
        }
    }

    // Split APK by ABI — disabled for AAB builds (Play Store handles ABI splits natively)
    // splits {
    //     abi {
    //         isEnable = true
    //         reset()
    //         include("arm64-v8a", "armeabi-v7a", "x86_64")
    //         isUniversalApk = true
    //     }
    // }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module"
            )
        }
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
