plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.altune"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }



    defaultConfig {
        applicationId = "app.altune"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val keyPropsFile = rootProject.file("key.properties")
            if (keyPropsFile.exists()) {
                val lines = keyPropsFile.readLines()
                val props = lines.associate { line ->
                    val (k, v) = line.split("=", limit = 2)
                    k.trim() to v.trim()
                }
                signingConfig = signingConfigs.create("release") {
                    storeFile = file(props["storeFile"]!!)
                    storePassword = props["storePassword"]!!
                    keyAlias = props["keyAlias"]!!
                    keyPassword = props["keyPassword"]!!
                }
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles("proguard-rules.pro")


        }
    }
}


flutter {
    source = "../.."
}
