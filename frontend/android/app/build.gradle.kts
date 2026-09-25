plugins {
    id("com.android.application")

    // The Flutter Gradle Plugin must be applied after
    // the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tactilelens.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_17

        targetCompatibility =
            JavaVersion.VERSION_17
    }

    defaultConfig {
    applicationId = "com.tactilelens.app"

    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion

    versionCode = flutter.versionCode
    versionName = flutter.versionName

    // PaddleOCR-VL is currently compiled specifically for
    // 64-bit ARM Android devices.
    ndk {
        abiFilters += listOf("arm64-v8a")
    }

    externalNativeBuild {
            cmake {
                cppFlags += listOf(
                    "-std=c++17",
                    "-fexceptions",
                )
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file(
                "src/main/cpp/CMakeLists.txt",
            )

            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            // Temporary signing configuration for
            // installing release builds on your phone.
            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(
        "com.microsoft.onnxruntime:onnxruntime-android:1.30.0",
    )
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl
                .JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
