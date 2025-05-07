import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
  // 1) Apply the Android and Kotlin plugins for this module
  id("com.android.application")
  id("org.jetbrains.kotlin.android")

  // 2) Flutter’s Gradle plugin and Google services
  id("dev.flutter.flutter-gradle-plugin")
  id("com.google.gms.google-services")
}

android {
  namespace = "com.ath.proximity"
  compileSdk = 35
  ndkVersion = "27.0.12077973"

  defaultConfig {
    applicationId = "com.ath.proximity"
    minSdk = 26
    targetSdk = 35
    versionCode = 1
    versionName = "1.0.0"
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true
  }

  // 3) Tell Gradle to include both java/ and kotlin/ source folders
  sourceSets {
    getByName("main") {
      java.srcDirs("src/main/java", "src/main/kotlin")
    }
  }

  buildTypes {
    getByName("release") {
      isMinifyEnabled = false
      isShrinkResources = false
      proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
      )
    }
  }
}

flutter {
  source = "../.."
}

dependencies {
  // 4) Match this stdlib version to whatever you set in settings.gradle.kts pluginManagement
  implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0")
  implementation("com.google.firebase:firebase-analytics-ktx:21.5.0")
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Ensure Kotlin emits Java 17 bytecode, not some invalid “21”
tasks.withType<KotlinCompile>().configureEach {
  kotlinOptions {
    jvmTarget = "17"
  }
}
