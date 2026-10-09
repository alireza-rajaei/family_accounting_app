allprojects {
    repositories {
        google()
        mavenCentral()
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

fun Project.forceCompileSdk36() {
    val androidExt = extensions.findByName("android") ?: return
    val clazz = androidExt.javaClass
    runCatching {
        clazz.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
            .invoke(androidExt, 36)
    }.recoverCatching {
        clazz.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
            .invoke(androidExt, 36)
    }
}

// Force plugins (e.g. file_picker) onto compileSdk 36 for AGP 9 AAR metadata checks.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        forceCompileSdk36()
    }
    pluginManager.withPlugin("com.android.application") {
        forceCompileSdk36()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
