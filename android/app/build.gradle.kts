plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystoreFile = file("../../keystore.jks")
val releaseStorePassword = System.getenv("KEYSTORE_PASSWORD")
val releaseKeyPassword = System.getenv("KEY_PASSWORD")
val releaseKeyAlias = System.getenv("KEY_ALIAS") ?: "pulse-money-key"

android {
    namespace = "com.pulsemoney.finance"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Signing configuration for release builds
    signingConfigs {
        create("release") {
            storeFile = releaseKeystoreFile
            keyAlias = releaseKeyAlias
            storePassword = releaseStorePassword ?: ""
            keyPassword = releaseKeyPassword ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.pulsemoney.finance"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Build for specific ABIs to reduce APK size
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Split APKs per ABI for smaller downloads
    bundle {
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { task ->
        task.path == ":app:assembleRelease" ||
            task.path == ":app:bundleRelease" ||
            task.name == "packageRelease"
    }

    if (releaseRequested) {
        require(releaseKeystoreFile.exists()) {
            "Release keystore not found at ${releaseKeystoreFile.path}"
        }
        require(!releaseStorePassword.isNullOrBlank()) {
            "KEYSTORE_PASSWORD not set for release signing"
        }
        require(!releaseKeyPassword.isNullOrBlank()) {
            "KEY_PASSWORD not set for release signing"
        }
    }
}
