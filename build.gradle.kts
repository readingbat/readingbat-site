plugins {
  java
  alias(libs.plugins.kotlin.jvm)
  alias(libs.plugins.versions)
  alias(libs.plugins.buildconfig)
  alias(libs.plugins.shadow)
}

repositories {
  google()
  mavenCentral()
//    mavenLocal()
  maven { url = uri("https://jitpack.io") }
}

val mainName = "ContentServer"
val appName = "server"

// This is for ./gradlew run
//application {
//    mainClassName = mainName
//}

//sourceCompatibility = JavaVersion.VERSION_17
//targetCompatibility = JavaVersion.VERSION_17

description = "ReadingBat Site"
group = "com.github.readingbat"
version = "2.1.0"

buildConfig {
  buildConfigField("String", "SITE_NAME", "\"${project.name}\"")
  buildConfigField("String", "SITE_VERSION", "\"${project.version}\"")
  buildConfigField("String", "SITE_RELEASE_DATE", "\"6/29/25\"")
}

dependencies {
  implementation(libs.readingbat.core)
  implementation(libs.kotlin.logging)
}

kotlin {
  jvmToolchain(17)
}

tasks.register("stage") {
  dependsOn("uberjar", "build", "clean")
}

tasks.named("build") {
  mustRunAfter("clean")
}

val uberJar by tasks.registering(Jar::class) {
  dependsOn(tasks.shadowJar)
  archiveFileName.set("server.jar")
  manifest {
    attributes("Main-Class" to "ContentServer")
  }
  from(zipTree(tasks.shadowJar.get().archiveFile))
}

tasks.shadowJar {
  isZip64 = true
  mergeServiceFiles()
  exclude("META-INF/*.SF")
  exclude("META-INF/*.DSA")
  exclude("META-INF/*.RSA")
  exclude("LICENSE*")
}

tasks.test {
  useJUnitPlatform()

  testLogging {
    events("passed", "skipped", "failed", "standardOut", "standardError")
    exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    showStandardStreams = true
  }
}