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
    val subproject = this
    subproject.configurations.all {
        resolutionStrategy {
            force("androidx.annotation:annotation-experimental:1.4.0")
            force("androidx.core:core:1.13.1")
        }
    }
    
    subproject.afterEvaluate {
        val androidExt = subproject.extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileSdkVersion(35)
            if (androidExt.namespace == null || androidExt.namespace!!.isEmpty()) {
                androidExt.namespace = subproject.group.toString().ifEmpty { "com.example.${subproject.name}" }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
