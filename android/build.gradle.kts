allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.annotation:annotation-experimental:1.3.0")
            force("androidx.core:core:1.13.1")
        }
    }
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.api.AndroidBasePlugin ||
            project.plugins.hasPlugin("com.android.library") ||
            project.plugins.hasPlugin("com.android.application")
        ) {
            val androidExt = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            androidExt?.let {
                it.compileSdkVersion(35)
                if (it.namespace == null || it.namespace!!.isEmpty()) {
                    it.namespace = project.group.toString().ifEmpty { "com.example.${project.name}" }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
