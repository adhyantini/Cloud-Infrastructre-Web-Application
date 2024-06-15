# Cloud Function

The cloud function here acts as a subscriber to the google pub/sub topic. It recives the messages sent by the google pub/sub topic, processes it and sends an email to the provided emailId along with a verification link.

## API's enabled:
1. Cloud Functions API
2. Cloud Pub/Sub API
3. Eventarc API
4. Cloud Run Admin API
5. Cloud Build API
