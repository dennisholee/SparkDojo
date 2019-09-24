package com.forest

import java.nio.charset.StandardCharsets
import org.apache.spark.sql.SparkSession
import org.apache.spark.streaming.{Seconds, StreamingContext}
import org.apache.spark.streaming.dstream.DStream
import org.apache.spark.streaming.pubsub.{PubsubUtils, PubsubInputDStream, SparkGCPCredentials}
import org.apache.spark.storage.StorageLevel

/**
 * @author ${user.name}
 */
object App {
  
  def main(args : Array[String]) {

    val projectId : String = "foo789-terraform-admin"
    val topic : Option[String] = None 
    val subscription : String = "ml-msg-src-subscription"

    val spark = SparkSession.builder.appName("stream-poc").getOrCreate()

    val sc = spark.sparkContext

    val ssc = new StreamingContext(sc, Seconds(1))

    val lines =  PubsubUtils.createStream(
      ssc,
      projectId,
      None,
      subscription,
      SparkGCPCredentials.builder.build(),
      StorageLevel.DISK_ONLY).map(message => new String(message.getData(), StandardCharsets.UTF_8))

//    val words = lines.flatMap(_.split(" "))
//    val pairs = words.map(word => (word, 1))
//    val wordCounts = pairs.reduceByKey(_ + _)

//    wordCounts.print()
lines.print()

    // messageStream.window(Seconds(60), Seconds(10)).print()

    ssc.start()
    ssc.awaitTerminationOrTimeout(1000 * 20)
  }


}
