import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// FIX: namespace for old plugins + JVM 17 for all
subprojects {
    afterEvaluate {
        // Fix namespace
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.getByType(
                com.android.build.gradle.LibraryExtension::class.java
            )
            if (android.namespace.isNullOrEmpty()) {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = javax.xml.parsers.DocumentBuilderFactory
                        .newInstance()
                        .newDocumentBuilder()
                        .parse(manifestFile)
                    val packageName = manifest.documentElement.getAttribute("package")
                    if (!packageName.isNullOrEmpty()) {
                        android.namespace = packageName
                    }
                }
            }
        }

        // Force Java 17
        if (project.plugins.hasPlugin("com.android.library") ||
            project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.getByType(
                com.android.build.api.dsl.CommonExtension::class.java
            )
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }

        // ✅ FIX: Use compilerOptions instead of deprecated kotlinOptions
        project.tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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