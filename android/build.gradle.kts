allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    buildDir = file("../../build/${project.path.removePrefix(":")}")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
