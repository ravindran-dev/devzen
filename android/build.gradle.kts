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
    val forceCompileSdk = 36
    
    val setSdk = Action<Project> {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val compileSdkMethod = android.javaClass.getMethod("compileSdk", Int::class.java)
                compileSdkMethod.invoke(android, forceCompileSdk)
            } catch (e: Exception) {
                try {
                    val compileSdkVersionMethod = android.javaClass.getMethod("compileSdkVersion", Int::class.java)
                    compileSdkVersionMethod.invoke(android, forceCompileSdk)
                } catch (e2: Exception) {
                    // Ignore
                }
            }
        }
    }

    if (project.state.executed) {
        setSdk.execute(project)
    } else {
        project.afterEvaluate(setSdk)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
