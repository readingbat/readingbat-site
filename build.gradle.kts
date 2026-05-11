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
  alias(libs.plugins.detekt)
  alias(libs.plugins.kotlinter)
}

description = "ReadingBat Site"

// ValueSources are read fresh on each build (configuration-cache-safe), so APP_RELEASE_DATE
// reflects the actual build time rather than a frozen configuration-cache value.
abstract class CurrentDateValueSource : ValueSource<String, ValueSourceParameters.None> {
  override fun obtain(): String =
    LocalDate.now().format(DateTimeFormatter.ofPattern("MM/dd/yyyy"))
}

val releaseDate = providers.of(CurrentDateValueSource::class) {}

buildConfig {
  packageName("com.readingbat.site")
  buildConfigField("String", "SITE_NAME", "\"${project.name}\"")
  buildConfigField("String", "SITE_VERSION", "\"${project.version}\"")
  buildConfigField("String", "SITE_RELEASE_DATE", releaseDate.map { "\"$it\"" })
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
  jvmToolchain(libs.versions.jvm.get().toInt())
}

application {
  mainClass = "ContentServerKt"
}

ktor {
  fatJar {
    archiveFileName = "server.jar"
  }
}

tasks.shadowJar {
  isZip64 = true
  duplicatesStrategy = DuplicatesStrategy.EXCLUDE
  listOf("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA", "LICENSE*").forEach { exclude(it) }
}

tasks.test {
  useJUnitPlatform()

  testLogging {
    events = setOf(TestLogEvent.PASSED, TestLogEvent.SKIPPED, TestLogEvent.FAILED, TestLogEvent.STANDARD_ERROR)
    exceptionFormat = TestExceptionFormat.FULL
    showStandardStreams = false
  }
}
