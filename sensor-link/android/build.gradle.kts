group = "com.kernel.sensor_link"
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
    namespace = "com.kernel.sensor_link"

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
                // Shared byte fixtures exported by firmware/reference (python -m kernel_ref.export).
                it.systemProperty("kernel.vectors", file("../../firmware/reference/vectors").absolutePath)
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
    // Required by the pigeon-generated bridge (suspend host and Flutter API methods).
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    // Pure JVM unit tests: protocol codec, auth vectors, QR parser, reconnect plan.
    // org.json gives the tests a real JSON parser (android.jar only has stubs).
    testImplementation(platform("org.junit:junit-bom:5.14.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.json:json:20240303")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
