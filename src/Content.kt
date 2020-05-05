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

val content =
  readingBatContent {
    +include(GitHubContent("readingbat-java-content")).java

    +include(GitHubContent("readingbat-python-content")).python

    +include(GitHubContent("readingbat-java-content")).kotlin
  }