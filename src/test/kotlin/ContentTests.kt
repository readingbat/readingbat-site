/*
 *   Copyright © 2026 Paul Ambrose (pambrose@mac.com)
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

import com.readingbat.kotest.TestSupport
import com.readingbat.kotest.TestSupport.answerAllWith
import com.readingbat.kotest.TestSupport.answerAllWithCorrectAnswer
import com.readingbat.kotest.TestSupport.forEachAnswer
import com.readingbat.kotest.TestSupport.forEachChallenge
import com.readingbat.kotest.TestSupport.forEachGroup
import com.readingbat.kotest.TestSupport.forEachLanguage
import com.readingbat.kotest.TestSupport.shouldHaveAnswer
import com.readingbat.kotest.TestSupport.testModule
import com.readingbat.posts.AnswerStatus
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