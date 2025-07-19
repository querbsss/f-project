allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

afterEvaluate {
    buildDir = file("../../build")
}

// subprojects {
//     afterEvaluate {
//         buildDir = file("${rootProject.buildDir}/${project.name}")
//     }
// }
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
