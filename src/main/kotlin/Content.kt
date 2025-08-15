import com.github.pambrose.common.util.OwnerType.Organization
import com.github.pambrose.common.util.OwnerType.User
import com.github.readingbat.dsl.GitHubContent
import com.github.readingbat.dsl.eval
import com.github.readingbat.dsl.readingBatContent

val content =
  readingBatContent {
    include(GitHubContent(Organization, "readingbat", "readingbat-java-content").eval(this).java)
    include(GitHubContent(Organization, "readingbat", "readingbat-python-content").eval(this).python)
    include(GitHubContent(Organization, "readingbat", "readingbat-java-content").eval(this).kotlin)

    include(GitHubContent(User, "maleich", "ReadingBat-content").eval(this).python, "Athenian: ")
  }