#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Clear existing alerts
for alert in $(gcloud alpha monitoring policies list --uri --filter='user_labels.managed:true'); do
  gcloud alpha monitoring policies delete $alert --quiet
done


# Logic to add notification channel with alerts.
# NOTIFICATION_CHANNEL_ID=$(gcloud beta monitoring channels list --filter='displayName="Platform Alert"' --format="value(name)")

# if [ -z "$NOTIFICATION_CHANNEL_ID" ]; then
#   # Creating notification channel
#   gcloud beta monitoring channels create \
#     --display-name="Platform Alert" \
#     --description="Primary contact for alerts" \
#     --type=email --channel-labels=email_address=example@google.com

#   NOTIFICATION_CHANNEL_ID=$(gcloud beta monitoring channels list --filter='displayName="Platform Alert"' --format="value(name)")
# fi

for dir in ./control-plane ./node ./pods ./system ./vm-workload; do
  for file in $dir/*; do
    gcloud alpha monitoring policies create \
      --policy-from-file=$file \
      --user-labels=managed=true # --notification-channels=$NOTIFICATION_CHANNEL_ID

  done
done