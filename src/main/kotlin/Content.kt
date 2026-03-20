import com.github.pambrose.common.util.OwnerType.Organization
import com.github.pambrose.common.util.OwnerType.User
import com.github.readingbat.dsl.GitHubContent
import com.github.readingbat.dsl.eval
import com.github.readingbat.dsl.readingBatContent

val content =
  readingBatContent {
    val jvmRepo = GitHubContent(Organization, "readingbat", "readingbat-java-content").eval(this)
    val pythonRepo = GitHubContent(Organization, "readingbat", "readingbat-python-content").eval(this)
    val athenianRepo = GitHubContent(User, "maleich", "ReadingBat-content").eval(this)

    include(jvmRepo.java)
    include(pythonRepo.python)
    include(jvmRepo.kotlin)
    include(athenianRepo.python, "Athenian: ")
  }