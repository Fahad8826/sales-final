plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.techfifo.sales"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.techfifo.sales"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

   buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        isMinifyEnabled = false
        isShrinkResources = false
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
    //kotlin
    // lint {
    //      abortOnError = false
    //     disable += "MissingPermission"
    //     baseline = file("lint-baseline.xml") 
    // }
}

flutter {
    source = "../.."
}

//kotlin
dependencies {
    // Media playback support (if you're using AndroidX Media)
    implementation("androidx.media:media:1.7.0")

    // Firebase BOM (centralized version management for Firebase)
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))

    // Firebase Auth (includes FirebaseAuth and FirebaseAuth.getInstance())
    implementation("com.google.firebase:firebase-auth-ktx")

    // Firebase Firestore (includes FirebaseFirestore and its extensions)
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Optional: If you're using Realtime Database or other Firebase features
    // implementation("com.google.firebase:firebase-database-ktx")

    // Google WebRTC (for PeerConnection, MediaStream, IceCandidate, etc.)
    implementation("io.github.webrtc-sdk:android:125.6422.07") 

    // Optional: If you need the WebRTC audio processing library
    implementation("androidx.core:core:1.12.0")

    implementation("com.google.android.gms:play-services-location:21.0.1")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}


