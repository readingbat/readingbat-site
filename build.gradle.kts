import org.gradle.api.tasks.testing.logging.TestExceptionFormat
import org.gradle.api.tasks.testing.logging.TestLogEvent
import java.time.LocalDate
import java.time.format.DateTimeFormatter

plugins {
  application
  alias(libs.plugins.kotlin.jvm)
  alias(libs.plugins.ktor.plugin)
  alias(libs.plugins.versions)
  alias(libs.plugins.buildconfig)
}

description = "ReadingBat Site"

val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
val releaseDate = (findProperty("releaseDate") as? String)?.takeIf { it.isNotBlank() } ?: LocalDate.now().format(formatter)

buildConfig {
  buildConfigField("String", "SITE_NAME", "\"${project.name}\"")
  buildConfigField("String", "SITE_VERSION", "\"${project.version}\"")
  buildConfigField("String", "SITE_RELEASE_DATE", "\"$releaseDate\"")
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

tasks.named("build") {
  mustRunAfter("clean")
}

tasks.test {
  useJUnitPlatform()

  testLogging {
    events = setOf(TestLogEvent.PASSED, TestLogEvent.SKIPPED, TestLogEvent.FAILED)
    exceptionFormat = TestExceptionFormat.FULL
    showStandardStreams = false
  }
}
