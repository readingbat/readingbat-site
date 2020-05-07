import com.github.readingbat.ReadingBatServer

object Server {
  @JvmStatic
  fun main(args: Array<String>) {
    ReadingBatServer.start(siteContent)
  }
}