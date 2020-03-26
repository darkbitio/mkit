#!/usr/bin/env bash

# Copyright 2020 Darkbit.io
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_id="${1}"
location="${2}"
clustername="${3}"

PROFILE_BASE_PATH="../profiles"
export PATH="/home/node/google-cloud-sdk/bin:$PATH"
OUTPUT_PATH="${HOME}/raw-results.json"
touch "${OUTPUT_PATH}"

# Run the GCP/GKE profile for cloud resources
echo -n "Generating results..."
cinc-auditor exec "${PROFILE_BASE_PATH}/inspec-profile-gke" -t gcp:// --input project_id="${project_id}" location="${location}" clustername="${clustername}" --reporter=json:- | ./inspec-results-parser.rb >> "${OUTPUT_PATH}"
echo "done."

# Get a valid kubeconfig inside the container
# two dashes means a zone, else region
if [[ "${location}" =~ ^.+\-.+\-.+$ ]]; then
  gcloud container clusters get-credentials --project "${project_id}" --zone "${location}" "${clustername}"
else
  gcloud container clusters get-credentials --project "${project_id}" --region "${location}" "${clustername}"
fi

# Run the K8s profile for workloads
./k8s.sh
