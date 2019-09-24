# Python Environment

```sh
# Create python virtual environment
virtualenv venv

# Activitate environment
venv/bin/activate

# Install Google PubSub library
pip install --upgrade google-cloud-pubsub

# Install Apache Beam
# Note: currently PySpark does not provide direct support to google pubsub
pip install apache-beam

```

# Scala setup
```
mvn archetype:generate

# Select net.alchim31.maven:scala-archetype-simple
mvn scala:run -DmainClass=com.forest.App
mvn scala:compile

# Set environment variable
export PROJECT=$(gcloud info --format='value(config.project)')
export JAR="stream-poc-1.0-SNAPSHOT.jar"
export SPARK_PROPERTIES="spark.dynamicAllocation.enabled=false,spark.streaming.receiver.writeAheadLog.enabled=true"
export ARGUMENTS="$PROJECT 60 20 60 hdfs:///user/spark/checkpoint"

# Submit job
gcloud dataproc jobs submit spark --cluster ml-cluster --async --jar target/stream-poc-1.0-SNAPSHOT.jar --max-failures-per-hour 10 --region asia-east2 --properties spark.dynamicAllocation.enabled=false,spark.streaming.receiver.writeAheadLog.enabled=true -- foo789-terraform-admin 60 20 60 hdfs:///user/spark/checkpoint
```

# Errors

```console
WARN org.apache.spark.streaming.scheduler.ReceiverTracker: Error reported by receiver for stream 0: Failed to pull messages - com.google.api.client.googleapis.json.GoogleJsonResponseException: 403 Forbidden
{
  "code" : 403,
  "errors" : [ {
    "domain" : "global",
    "message" : "Request had insufficient authentication scopes.",
    "reason" : "forbidden"
  } ],
  "message" : "Request had insufficient authentication scopes.",
  "status" : "PERMISSION_DENIED"
}
```

Ensure service account has pubsub subscription permission i.e.:

```hcl
resource "google_project_iam_binding" "sa-pubsub-iam" {
   role   = "roles/pubsub.subscriber"
   members = ["serviceAccount:${google_service_account.sa.email}"]
}
```
