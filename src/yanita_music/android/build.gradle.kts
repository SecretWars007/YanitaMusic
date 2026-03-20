allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://s01.oss.sonatype.org/content/repositories/releases/") }
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://raw.githubusercontent.com/arthenica/ffmpeg-kit-flutter/main/m2repository") }
        maven { url = uri("https://raw.githubusercontent.com/arthenica/ffmpeg-kit/master/m2repository") }
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
