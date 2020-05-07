import com.github.readingbat.dsl.GitHubContent
import com.github.readingbat.dsl.include
import com.github.readingbat.dsl.readingBatContent

val organization = "readingbat"
val javaRepo = "readingbat-java-content"
val pythonRepo = "readingbat-python-content"
val branch = "master"

val siteContent =
  readingBatContent {
    +include(GitHubContent(organization, javaRepo, branch = branch)).java
    +include(GitHubContent(organization, pythonRepo, branch = branch, srcPath = "src")).python
    +include(GitHubContent(organization, javaRepo, branch = branch)).kotlin
  }