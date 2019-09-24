from faker import Faker
from google.cloud import pubsub
import json

fake = Faker()


def generate_msg():
    fake = Faker()
    
    msg = {}
    msg['name']    = fake.name()
    msg['message'] = fake.sentence()
    return msg


PROJECT    = "foo789-terraform-admin"
TOPIC_NAME = "ml-msg-src-topic"

publisher = pubsub.PublisherClient()
topic_url = 'projects/{project_id}/topics/{topic}'.format(
    project_id=PROJECT,
    topic=TOPIC_NAME,
)

msg = generate_msg()

print( json.dumps(msg) )

publisher.publish(topic_url, json.dumps(msg).encode('utf-8'))
