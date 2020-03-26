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

awsregion="${1}"
clustername="${2}"

PROFILE_BASE_PATH="../profiles"
OUTPUT_PATH="${HOME}/raw-results.json"
touch "${OUTPUT_PATH}"

# Run the GCP/GKE profile for cloud resources
echo -n "Generating results..."
cinc-auditor exec "${PROFILE_BASE_PATH}/inspec-profile-eks" -t aws:// --input awsregion="${awsregion}" clustername="${clustername}" --reporter=json:- | ./inspec-results-parser.rb >> "${OUTPUT_PATH}"
echo "done."

# Get a valid kubeconfig inside the container
aws eks --region "${awsregion}" update-kubeconfig --name "${clustername}"

# Run the K8s profile for workloads
./k8s.sh
