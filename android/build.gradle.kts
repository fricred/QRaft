plugins {
    // Firebase google-services plugin (Phase 1 plan 01-03 — minimum wiring per D-01).
    // Declared with `apply false` here so the app-level build.gradle.kts can apply it.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // home_widget declares glance-appwidget:1.+, which now resolves to
    // 1.3.0-alpha01 (requires compileSdk 37 + AGP 9.1.0). Pin to the stable
    // release this project compiles against.
    configurations.all {
        resolutionStrategy {
            force("androidx.glance:glance:1.1.1")
            force("androidx.glance:glance-appwidget:1.1.1")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Normalize the JVM target across every module to 17. Two conflicting groups of
// plugins forced this: home_widget 0.9.x hardcodes jvmTarget 1.8 yet pulls androidx
// artifacts (work-runtime:2.+) built as JVM 11 bytecode, which Kotlin refuses to
// inline; meanwhile the FlutterFire plugins compile Java at 17. Java and Kotlin must
// agree per module or KGP's JVM-target consistency check fails the build, so 17 — the
// current Flutter/AGP baseline — is the one value that satisfies everything.
// The Java override has to run in afterEvaluate: a plugins.withId callback fires at
// plugin-application time, before the subproject's own android { compileOptions { … } }
// block, so the plugin's hardcoded value would win. This block must therefore stay
// ABOVE the evaluationDependsOn(":app") below — that call evaluates subprojects
// eagerly, and afterEvaluate cannot be registered on an already-evaluated project.
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
