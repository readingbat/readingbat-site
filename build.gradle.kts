import java.time.LocalDate
import java.time.format.DateTimeFormatter
import org.gradle.api.tasks.testing.logging.TestLogEvent

plugins {
  application
  alias(libs.plugins.kotlin.jvm)
  alias(libs.plugins.ktor.plugin)
  alias(libs.plugins.versions)
  alias(libs.plugins.buildconfig)
}

repositories {
  google()
  mavenCentral()
  maven { url = uri("https://jitpack.io") }
}

description = "ReadingBat Site"
group = "com.github.readingbat"
version = "3.1.3"

val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")

buildConfig {
  buildConfigField("String", "SITE_NAME", "\"${project.name}\"")
  buildConfigField("String", "SITE_VERSION", "\"${project.version}\"")
  buildConfigField("String", "SITE_RELEASE_DATE", "\"${LocalDate.now().format(formatter)}\"")
}

dependencies {
  implementation(libs.readingbat.core)
  implementation(libs.kotlin.logging)

  implementation(platform(libs.ktor.bom))
  testImplementation(libs.ktor.server.test.host)

  testImplementation(libs.readingbat.kotest)

  testImplementation(libs.kotest.runner.junit5)
  testImplementation(libs.kotest.assertions.core)
  testImplementation(libs.kotest.assertions.ktor)
}

kotlin {
  jvmToolchain(21)
}

application {
  mainClass = "ContentServerKt"
}

ktor {
  fatJar {
    archiveFileName.set("server.jar")
  }
}

tasks.shadowJar {
  isZip64 = true
  duplicatesStrategy = DuplicatesStrategy.EXCLUDE
  exclude("META-INF/*.SF")
  exclude("META-INF/*.DSA")
  exclude("META-INF/*.RSA")
  exclude("LICENSE*")
}

// Heroku-only
//tasks.register("stage") {
//  dependsOn("build")
//}

tasks.named("build") {
  mustRunAfter("clean")
}

tasks.test {
  useJUnitPlatform()

  testLogging {
    events = setOf(TestLogEvent.PASSED, TestLogEvent.SKIPPED, TestLogEvent.FAILED)
    exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    showStandardStreams = true
  }
}

configurations.all {
  resolutionStrategy.cacheChangingModulesFor(0, "seconds")
}
