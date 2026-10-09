group = "com.kernel.audio_ai"
version = "0.2.0"

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
    namespace = "com.kernel.audio_ai"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
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
    // Required by the pigeon-generated bridge (suspend host methods).
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    // LiteRT (formerly TensorFlow Lite) on-device interpreter, CPU only.
    // Only used when a real .tflite model plus manifest is bundled in
    // src/main/assets/models/. No network, no model download.
    // Pinned to 1.4.x on purpose: litert 2.x pulls in Play AI/asset delivery
    // (com.google.android.play:ai-delivery -> asset-delivery, androidx.work),
    // which adds network-capable download services and permissions
    // (FOREGROUND_SERVICE_DATA_SYNC, ACCESS_NETWORK_STATE, ...). That breaks the
    // no-network, bundled-model-only guardrail. 1.4.2 has no transitive deps.
    implementation("com.google.ai.edge.litert:litert:1.4.2")

    // Unit tests are pure JVM (quality gate, log-mel, resampler, WAV, model
    // manifest). No Android framework or test doubles are needed.
    testImplementation(platform("org.junit:junit-bom:5.14.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
