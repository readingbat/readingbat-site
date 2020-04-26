import com.github.readingbat.ReadingBatServer
import com.github.readingbat.readingBatContent
import com.github.readingbat.remoteContent

object Main {
    @JvmStatic
    fun main(args: Array<String>) {
        ReadingBatServer.start(content)
    }
}

val content =
    readingBatContent {

        +remoteContent(repo = "readingbat-java-content").java

        +remoteContent(repo = "readingbat-python-content").python

    }

