group = "com.kernel.sense_ai"
version = "0.1.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.kernel.sense_ai"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("androidTest") {
            assets.srcDirs("src/test/resources")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    testOptions {
        unitTests {
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed")
                    showStandardStreams = false
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // CameraX: Preview + ImageAnalysis (Stage 0, Y plane only) + ImageCapture
    // (full-resolution stills), plus PreviewView for the Flutter platform view.
    // The app may resolve a newer 1.x (mobile_scanner pins 1.6.1); CameraX
    // aligns every camera-* artifact to the same version.
    val cameraX = "1.5.1"
    implementation("androidx.camera:camera-core:$cameraX")
    implementation("androidx.camera:camera-camera2:$cameraX")
    implementation("androidx.camera:camera-lifecycle:$cameraX")
    implementation("androidx.camera:camera-view:$cameraX")

    // ARCore depth for the Measure screen. Declared "optional" in the
    // manifest: the app installs and runs on devices without ARCore (the
    // global iQOO 15 I2501 is not on the supported list), and support is
    // checked at run time. ARCore adds no INTERNET permission.
    implementation("com.google.ar:core:1.56.0")

    // LiteRT interpreter for the sound pre-filter (YAMNet-class model). The
    // model file is resolved by the app through model-hub and passed in as a
    // path; nothing is bundled or downloaded here. 1.4.2 has no transitive
    // dependencies (no Play asset delivery), same pin as audio-ai.
    implementation("com.google.ai.edge.litert:litert:1.4.2")

    // Required by the pigeon-generated bridge (suspend host methods).
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    // Unit tests are pure JVM (Stage 0 detectors, spectral flux, WAV writer,
    // tile geometry, distance gates, thermal policy).
    testImplementation(platform("org.junit:junit-bom:5.14.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
