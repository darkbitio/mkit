#!/usr/bin/env ruby

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

require 'optparse'
require 'json'

# Begin Pry hack
# prepare new stdin to satisfy pry
pry_fd_stdin = IO.sysopen("/dev/tty")
pry_stdin = IO.new(pry_fd_stdin, "r")

# load pry and cheat it with our stdio
require 'pry'
Pry.config.input = pry_stdin
# End Pry Hack

# Collect options
@options = {}
OptionParser.new do |opts|
  opts.on("-h", "--help", "Show help information") do
    puts opts
    puts ""
    puts "Example: inspec exec . --reporter json | ./inspec-results-parser.rb"
    puts "prints jsonlines of results"
    exit
  end
end.parse!

# Load Inspec results from standard in
results = begin
  JSON.load($stdin.read)
rescue ArgumentError => e
  puts "Could not parse JSON: #{e.message}"
end

# Calculate the results block
def derive_results(resources)
  # Total resources 
  total = resources.count
  # Count the passing resources
  passed_count = 0
  resources.map{|r| if r['status'] == 'passed' then passed_count += 1 end }
  # Set passing if all are passed
  status = 'failed'
  status = 'passed' if passed_count >= total
  # Return hash
  return {'status'=>status, 'passed'=>passed_count, 'total'=>total}
end

# Return an array of hashes for passed/failed and resource name
def parse_resources(results)
  # Resource name is everything to the left of the colon in the "describe" string
  mapped = {}
  final_results = []
  results.map do |result|
     status = result['status']
     resource = result["code_desc"].scan(/^(.+):.+$/).last.first
     mapped[resource] = status if mapped[resource].nil? || mapped[resource] == "passed"
  end
  mapped.keys.each { |result| final_results.push({"status"=>"#{mapped[result]}", "resource"=>"#{result}"}) }
  return final_results
end

# Fetch an arbitrary tag by name if it exists
def parse_tags(tags, type)
  return tags["#{type}"] unless tags["#{type}"].nil?
  return "N/A"
end

# Fetch an arbitrary description by label if it exists
def parse_description(descriptions, type)
  desc = descriptions.select{|desc| desc["label"] == "#{type}" }
  return desc.first["data"] unless desc.empty?
  return "N/A"
end

# Parse the Inspec JSON output
# Loop through all profiles used
results.dig("profiles").each do |profile|
  # Loop through all valid controls run
  profile.dig("controls").each do |control|
    # Create a "result" JSON Lines output
    result = {}
    result["version"] = 1
    result["platform"] = parse_tags(control["tags"], "platform")
    result["category"] = parse_tags(control["tags"], "category")
    result["resource"] = parse_tags(control["tags"], "resource")
    result["title"] = control["title"] || "Untitled Control"
    result["description"] = parse_description(control["descriptions"], "default")
    result["remediation"] = parse_description(control["descriptions"], "remediation")
    result["validation"] = parse_description(control["descriptions"], "validation")
    result["severity"] = control["impact"] || "1.0"
    result["effort"] = parse_tags(control["tags"], "effort")
    result["references"] = control["refs"]
    result["resources"] = parse_resources(control["results"])
    result["result"] = derive_results(result["resources"])
    puts result.to_json
  end
end
