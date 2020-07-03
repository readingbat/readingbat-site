import com.github.readingbat.dsl.GitHubContent
import com.github.readingbat.dsl.eval
import com.github.readingbat.dsl.readingBatContent

val organization = "readingbat"
val javaRepo = "readingbat-java-content"
val pythonRepo = "readingbat-python-content"
val branch = "master"

val content =
  readingBatContent {
    include(GitHubContent(organization, javaRepo, branch = branch).eval().java)
    include(GitHubContent(organization, pythonRepo, branch = branch, srcPath = "src").eval().python)
    include(GitHubContent(organization, javaRepo, branch = branch).eval().kotlin)
  }
