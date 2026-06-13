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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
