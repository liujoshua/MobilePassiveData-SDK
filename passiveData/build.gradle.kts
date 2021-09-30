import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties
import org.jetbrains.kotlin.gradle.plugin.mpp.KotlinNativeTarget

plugins {
    kotlin("multiplatform")
    id("com.android.library")
    kotlin("plugin.serialization")
    id("maven-publish")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions.jvmTarget = "1.8"
}

android {
    sourceSets["main"].manifest.srcFile("src/androidMain/AndroidManifest.xml")
    sourceSets["main"].res.srcDirs("src/androidMain/res")
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}

kotlin {
    android {
        publishAllLibraryVariants()

        tasks.withType<Test> {
            systemProperty(
                "openWeatherApiKey",
                gradleLocalProperties(rootProject.rootDir)
                    .getProperty("openWeatherApiKey")
                    ?: System.getenv("OPEN_WEATHER_API_KEY")
            )
            systemProperty(
                "airNowApiKey",
                gradleLocalProperties(rootProject.rootDir)
                    .getProperty("airNowApiKey")
                    ?: System.getenv("AIR_NOW_API_KEY")
            )
        }
    }

    val iosTarget: (String, KotlinNativeTarget.() -> Unit) -> KotlinNativeTarget =
        if (System.getenv("SDK_NAME")?.startsWith("iphoneos") == true)
            ::iosArm64
        else
            ::iosX64

    iosTarget("ios") {
        binaries {
            framework {
                baseName = "passiveData"
            }
        }
    }
    sourceSets {
        val commonMain by getting {
            dependencies {
                implementation(Deps.Coroutines.core) {
                    version {
                        strictly(Versions.kotlinCoroutines)
                    }
                }

                implementation(Deps.KotlinX.dateTime)
                api(Deps.KotlinX.serializationJson)

                implementation(Deps.Ktor.clientCore)
                //Is api to give depending modules access to JsonElement
                api(Deps.Ktor.clientSerialization)
                implementation(Deps.Ktor.clientLogging)

                // koin
                api(Deps.Koin.core)

                implementation(Deps.Napier.napier)

                implementation("com.google.android.gms:play-services-location:18.0.0")

            }
        }
        val commonTest by getting {
            dependencies {
                implementation(kotlin("test-common"))
                implementation(kotlin("test-annotations-common"))

                implementation(Deps.Ktor.clientMock)

                implementation(Deps.Ktor.clientMock)
                api(Deps.Koin.test)
            }
        }
        val androidMain by getting {
            dependencies {
                api(Deps.Coroutines.android)

                api(Deps.AssessmentModel.sdk)
                implementation(Deps.Ktor.clientAndroid)
                implementation(Deps.Koin.android)

                // TODO: experimental
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-rx2:${Versions.kotlinCoroutines}")
            }
        }
        val androidTest by getting {
            dependencies {
                implementation(Deps.Coroutines.test)
                implementation(kotlin("test-junit"))
                implementation("junit:junit:4.13.2")
            }
        }
        val iosMain by getting {
            dependencies {
                implementation(Deps.Ktor.clientIos)
            }
        }
        val iosTest by getting
    }
}

android {
    compileSdkVersion(30)
    sourceSets["main"].manifest.srcFile("src/androidMain/AndroidManifest.xml")
    defaultConfig {
        minSdkVersion(19)
        targetSdkVersion(30)
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}
