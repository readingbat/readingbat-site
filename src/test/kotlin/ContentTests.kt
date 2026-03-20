import com.github.readingbat.kotest.TestSupport
import com.github.readingbat.kotest.TestSupport.answerAllWith
import com.github.readingbat.kotest.TestSupport.answerAllWithCorrectAnswer
import com.github.readingbat.kotest.TestSupport.forEachAnswer
import com.github.readingbat.kotest.TestSupport.forEachChallenge
import com.github.readingbat.kotest.TestSupport.forEachGroup
import com.github.readingbat.kotest.TestSupport.forEachLanguage
import com.github.readingbat.kotest.TestSupport.shouldHaveAnswer
import com.github.readingbat.kotest.TestSupport.testModule
import com.github.readingbat.posts.AnswerStatus
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldBeBlank
import io.ktor.server.testing.testApplication

class ContentTests : StringSpec() {
  init {
    beforeTest {
      TestSupport.initTestProperties()
    }

    "Test all challenges" {
      testApplication {
        application { testModule(content) }

        content.forEachLanguage {
          forEachGroup {
            forEachChallenge {
              answerAllWith(this@testApplication, "") {
                answerStatus shouldBe AnswerStatus.NOT_ANSWERED
                hint.shouldBeBlank()
              }

              answerAllWith(this@testApplication, "wrong answer") {
                answerStatus shouldBe AnswerStatus.INCORRECT
              }

              answerAllWithCorrectAnswer(this@testApplication) {
                answerStatus shouldBe AnswerStatus.CORRECT
                hint.shouldBeBlank()
              }
            }
          }
        }
      }
    }

    "Test with correct answers" {
      testApplication {
        application { testModule(content) }
        content.forEachLanguage {
          forEachGroup {
            forEachChallenge {
              forEachAnswer {
                it shouldHaveAnswer correctAnswers[it.index]
              }
            }
          }
        }
      }
    }
  }
}