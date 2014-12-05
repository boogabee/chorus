#!/usr/bin/env ruby

# Usage: ruby ddos.rb HOST USERNAME CONNECTION-COUNT
#   DDOS.rb - saturate a postgres server

HOST = ARGV[0] || "192.168.33.10"
USER = ARGV[1] || "vagrant"
CONNECTION_COUNT = (ARGV[2] || 250).to_i

threads = []

CONNECTION_COUNT.times do
  threads << Thread.new { print "."; `psql -h #{HOST} -U #{USER} postgres` }
end

threads.each { |thread| thread.join }
