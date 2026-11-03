pluginManagement {
  repositories {
    gradlePluginPortal()
    mavenCentral()
  }
}

plugins {
  id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    mavenCentral()
    // A readingbat-core version that is never published to Maven Central comes from the local Maven repo
    // (`make publish-local` in readingbat-core). It must be a readingbat-core tag: CI builds it from the tag,
    // and `make release-check` refuses one that is neither on Central nor tagged. Central is searched first,
    // so it supplies any version it has.
    mavenLocal {
      content { includeGroup("com.readingbat") }
    }
  }
}

rootProject.name = "readingbat-site"
