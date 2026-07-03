import com.github.benmanes.gradle.versions.updates.DependencyUpdatesTask
import org.gradle.api.tasks.testing.logging.TestExceptionFormat
import org.gradle.api.tasks.testing.logging.TestLogEvent
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.time.LocalDate
import java.time.format.DateTimeFormatter

plugins {
  // `application` is applied transitively by the Ktor plugin (io.ktor.plugin), which also wires
  // up `mainClass`, `run`, and `buildFatJar`; no need to declare it explicitly.
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

application {
  mainClass = "ContentServerKt"
}

configureKotlin()
configureDetekt()
configureKotlinter()
configureKtor()
configureShadowJar()
configureTest()
configureVersions()

fun Project.configureKotlin() {
  kotlin {
    jvmToolchain(libs.versions.jvm.get().toInt())
  }

  // Run the unused-return-value checker over production code only. Kotest's
  // assertion DSL (e.g. shouldBe) returns its receiver, and tests intentionally
  // discard that result, so applying the checker to the test source set would
  // emit only false-positive warnings.
  tasks.named<KotlinCompile>("compileKotlin") {
    compilerOptions {
      freeCompilerArgs.add("-Xreturn-value-checker=check")
    }
  }
}

fun Project.configureDetekt() {
  detekt {
    source.setFrom("src/main/kotlin", "src/test/kotlin")
    buildUponDefaultConfig = true
    parallel = true
  }
}

fun Project.configureKotlinter() {
  kotlinter {
    ignoreFormatFailures = false
    ignoreLintFailures = false
    reporters = arrayOf("checkstyle", "plain")
  }
}

fun Project.configureKtor() {
  ktor {
    fatJar {
      archiveFileName = "server.jar"
    }
  }
}

fun Project.configureShadowJar() {
  tasks.shadowJar {
    isZip64 = true
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    listOf("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA").forEach { exclude(it) }
  }
}

fun Project.configureTest() {
  tasks.test {
    useJUnitPlatform()

    testLogging {
      events = setOf(TestLogEvent.PASSED, TestLogEvent.SKIPPED, TestLogEvent.FAILED, TestLogEvent.STANDARD_ERROR)
      exceptionFormat = TestExceptionFormat.FULL
      showStandardStreams = false
    }
  }
}

fun Project.configureVersions() {
  // A pre-release qualifier is a `.` or `-` delimiter followed by a known unstable
  // keyword. `m\d` matches milestones (`-M1`/`.M2`) without catching stable classifiers
  // like `-macos`/`-MR1`, and the `[.-]` delimiter catches both dash-style (`-alpha`)
  // and dot-style (Netty's `.Beta1`) qualifiers while leaving `-jre`/`.Final` stable.
  val preReleaseQualifier =
    Regex("""[.-](rc|beta|alpha|m\d|cr|snapshot|eap|dev|milestone|pre)""", RegexOption.IGNORE_CASE)

  fun isNonStable(version: String): Boolean = preReleaseQualifier.containsMatchIn(version)

  tasks.withType<DependencyUpdatesTask>().configureEach {
    notCompatibleWithConfigurationCache("the dependency updates plugin is not compatible with the configuration cache")
    // Reject a pre-release candidate only when the current version is stable. For
    // dependencies we intentionally track on a pre-release line (e.g. a detekt
    // alpha), newer pre-releases are still surfaced as available updates.
    rejectVersionIf {
      isNonStable(candidate.version) && !isNonStable(currentVersion)
    }
  }
}
