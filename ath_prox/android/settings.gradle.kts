// android/settings.gradle.kts
pluginManagement {
    // 1) Locate the Flutter SDK so we can load its Gradle plugin
    val flutterSdkPath = run {
        val props = java.util.Properties()
        file("local.properties").inputStream().use { props.load(it) }
        props.getProperty("flutter.sdk")
            ?: error("flutter.sdk not set in local.properties")
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // 2) Where to find all the Gradle plugins we declare below
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter’s plugin-loader — this must be first
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Android / Kotlin / Google-Services — declare but don’t auto-apply
    id("com.android.application")         version "8.9.2" apply false
    id("org.jetbrains.kotlin.android")    version "2.1.0"  apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
}

include(":app")
