#!/bin/bash

# Clear existing alerts
for alert in $(gcloud alpha monitoring policies list --uri --filter='user_labels.managed:true'); do
  gcloud alpha monitoring policies delete $alert --quiet
done


# Logic to add notification channel with alerts. Commented out so we don't add
# the oncall email address into test projects. 
# NOTIFICATION_CHANNEL_ID=$(gcloud beta monitoring channels list --filter='displayName="Google Alert"' --format="value(name)")

# if [ -z "$NOTIFICATION_CHANNEL_ID" ]; then
#   # Creating notification channel
#   gcloud beta monitoring channels create \
#     --display-name="Google Alert" \
#     --description="Primary google contact for alerts" \
#     --type=email --channel-labels=email_address=gdc-hypercare-oncall-external@google.com

#   NOTIFICATION_CHANNEL_ID=$(gcloud beta monitoring channels list --filter='displayName="Google Alert"' --format="value(name)")
# fi

for dir in ./control-plane ./node ./pods ./system ./vm-workload; do
  for file in $dir/*; do
    gcloud alpha monitoring policies create \
      --policy-from-file=$file \
      --user-labels=managed=true # --notification-channels=$NOTIFICATION_CHANNEL_ID

  done
done