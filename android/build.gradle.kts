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
    subproject.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.api.AndroidBasePlugin ||
            subproject.plugins.hasPlugin("com.android.library") ||
            subproject.plugins.hasPlugin("com.android.application")
        ) {
            val androidExt = subproject.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            androidExt?.let {
                it.compileSdkVersion(36)
                if (it.namespace == null || it.namespace!!.isEmpty()) {
                    it.namespace = subproject.group.toString().ifEmpty { "com.example.${subproject.name}" }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
