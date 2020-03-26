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

INPUT_PATH="${HOME}/raw-results.json"
OUTPUT_PATH="${HOME}/ui/results.json"
UI_PATH="${HOME}/ui"

cat "${INPUT_PATH}" | ./inspec-results-formatter.rb >> "${OUTPUT_PATH}"

echo ""
echo "Visit http://localhost:8000 to view the results"

cd "${UI_PATH}"
yarn start
