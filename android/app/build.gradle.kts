plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase integration
}

android {
    namespace = "com.example.tinkerly"
    
    compileSdk = 35 // ✅ Fixes all SDK compatibility issues
    ndkVersion = "27.2.12479018" // ✅ Your installed NDK version

    defaultConfig {
        applicationId = "com.example.tinkerly"
        minSdk = 23
        targetSdk = 35 // ✅ Match compileSdk for newer APIs
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // Replace with real keystore in production
            signingConfig = signingConfigs.getByName("debug") 
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}
