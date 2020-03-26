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
require 'jsonl'

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
    puts "Example: results.json | ./inspec-results-formatter.rb"
    exit
  end
end.parse!

# Load Inspec results from standard in
results = begin
  JSONL.parse($stdin.read)
rescue ArgumentError => e
  puts "Could not parse JSON: #{e.message}"
end

combined_results = {}
combined_results['summary'] = {}
combined_results['version'] = "2.0.0"
combined_results['results'] = []
results.each do |result|
  combined_results['results'] << result
end
puts combined_results.to_json
