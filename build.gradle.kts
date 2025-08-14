import java.time.LocalDate
import java.time.format.DateTimeFormatter

plugins {
  java
  application
  alias(libs.plugins.kotlin.jvm)
  alias(libs.plugins.versions)
  alias(libs.plugins.buildconfig)
  alias(libs.plugins.ktor.plugin)
}

repositories {
  google()
  mavenCentral()
  maven { url = uri("https://jitpack.io") }
}

val mainName = "ContentServer"
val appName = "server"

// This is for ./gradlew run
application {
  mainClass.set(mainName)
}

description = "ReadingBat Site"
group = "com.github.readingbat"
version = "2.1.0"

val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")

buildConfig {
  buildConfigField("String", "SITE_NAME", "\"${project.name}\"")
  buildConfigField("String", "SITE_VERSION", "\"${project.version}\"")
  buildConfigField("String", "SITE_RELEASE_DATE", "\"${LocalDate.now().format(formatter)}\"")
}

dependencies {
  implementation(libs.readingbat.core)
  implementation(libs.kotlin.logging)
}

kotlin {
  jvmToolchain(17)
}

tasks.register("stage") {
  dependsOn("build", "clean")
}

tasks.named("build") {
  mustRunAfter("clean")
}


ktor {
  fatJar {
    archiveFileName.set("server.jar")
  }
}

tasks.shadowJar {
  setZip64(true)
  isZip64 = true
  duplicatesStrategy = DuplicatesStrategy.EXCLUDE
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