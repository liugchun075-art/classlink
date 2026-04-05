plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.classlink"
    
    // 💡 核心修复 1：写死最高编译版本 35，满足最新图片插件要求
    compileSdk = 35

    // 💡 核心修复 2：只保留这一行写死的 NDK 版本，绝对不能有重复的 ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 建议升级到 Java 17，现代安卓开发标配
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.classlink"
        
        // 💡 核心修复 3：写死目标版本 35
        minSdk = 24
        targetSdk = 35
        
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}