group = "com.kernel.local_llm"
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
    namespace = "com.kernel.local_llm"

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
        // LiteRT-LM 0.18.0 declares minSdkVersion 24.
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
    // Required by the pigeon-generated bridge and the generation/import jobs.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    // Google AI Edge LiteRT-LM: on-device LLM runtime, used text-only.
    // Pinned exactly (never latest.release). 0.18.0 pulls only gson,
    // kotlin-reflect and kotlinx-coroutines: no Play services, no asset
    // delivery, no download service, no permissions. Its only native library
    // is liblitertlm_jni.so (arm64-v8a, x86_64), which does not clash with
    // audio-ai's LiteRT 1.4.2 (libtensorflowlite_jni.so).
    implementation("com.google.ai.edge.litertlm:litertlm-android:0.18.0")

    // Unit tests are pure JVM (engine config builder, sidecar, import
    // checks). No Android framework and no test doubles of the runtime.
    testImplementation(platform("org.junit:junit-bom:5.14.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
