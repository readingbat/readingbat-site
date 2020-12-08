import com.github.pambrose.common.util.*
import com.github.readingbat.TestSupport.answerAllWith
import com.github.readingbat.TestSupport.answerAllWithCorrectAnswer
import com.github.readingbat.TestSupport.forEachAnswer
import com.github.readingbat.TestSupport.forEachChallenge
import com.github.readingbat.TestSupport.forEachGroup
import com.github.readingbat.TestSupport.forEachLanguage
import com.github.readingbat.TestSupport.shouldHaveAnswer
import com.github.readingbat.TestSupport.testModule
import com.github.readingbat.common.*
import com.github.readingbat.common.Property.*
import com.github.readingbat.dsl.*
import com.github.readingbat.posts.*
import com.github.readingbat.posts.AnswerStatus.*
import com.github.readingbat.server.*
import io.kotest.core.spec.style.*
import io.kotest.matchers.*
import io.kotest.matchers.string.*
import io.ktor.application.*
import io.ktor.server.engine.*
import io.ktor.server.testing.*

class ContentTests : StringSpec({

  "Test all challenges" {
    withTestApplication({ testModule(content) }) {

      content.forEachLanguage {
        forEachGroup {
          forEachChallenge {
            answerAllWith(this@withTestApplication, "") {
              answerStatus shouldBe NOT_ANSWERED
              message.shouldBeBlank()
            }

            answerAllWith(this@withTestApplication, "wrong answer") {
              answerStatus shouldBe INCORRECT
            }

            answerAllWithCorrectAnswer(this@withTestApplication) {
              answerStatus shouldBe CORRECT
              message.shouldBeBlank()
            }
          }
        }
      }
    }
  }

  "Test with correct answers" {
    withTestApplication({ testModule(content) }) {
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
})