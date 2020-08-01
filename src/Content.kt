import com.github.pambrose.common.util.OwnerType.Organization
import com.github.pambrose.common.util.OwnerType.User
import com.github.readingbat.dsl.GitHubContent
import com.github.readingbat.dsl.eval
import com.github.readingbat.dsl.readingBatContent

val org = "readingbat"
val javaRepo = "readingbat-java-content"
val pythonRepo = "readingbat-python-content"

val content =
  readingBatContent {
    include(GitHubContent(Organization, org, javaRepo).eval(this).java)
    include(GitHubContent(Organization, org, pythonRepo, srcPath = "src").eval(this).python)
    include(GitHubContent(Organization, org, javaRepo).eval(this).kotlin)

    include(GitHubContent(User, "maleich", "ReadingBat-content").eval(this).python, "Athenian: ")
  }