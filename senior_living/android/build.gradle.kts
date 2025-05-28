buildscript {
    val kotlinVersion = "1.9.23"
    val agpVersion = "8.2.2"
    val ndkVersion = "26.3.11579264" // Update to match your installed NDK version

    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:$agpVersion")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set NDK version for all Android projects
subprojects {
    project.plugins.withId("com.android.application") {
        project.extensions.configure<com.android.build.gradle.AppExtension> {
            ndkVersion = "26.3.11579264" // Update here too
        }
    }
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.gradle.LibraryExtension> {
            ndkVersion = "26.3.11579264" // Update here too
        }
    }
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}

rootProject.layout.buildDirectory.set(project.layout.projectDirectory.dir("../build"))

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
