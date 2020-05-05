import com.github.readingbat.ReadingBatServer
import com.github.readingbat.dsl.GitHubContent
import com.github.readingbat.dsl.include
import com.github.readingbat.dsl.readingBatContent

object Main {
  @JvmStatic
  fun main(args: Array<String>) {
    ReadingBatServer.start(content)
  }
}

val organization = "readingbat"
val branch = "dev"

val content =
  readingBatContent {
    +include(GitHubContent(organization, "readingbat-java-content", branch = branch)).java

    +include(GitHubContent(organization, "readingbat-python-content", branch = branch, srcPath = "src")).python

    +include(GitHubContent(organization, "readingbat-java-content", branch = branch)).kotlin
  }