#!/usr/bin/ruby
#
# Run script like './indices.rb elastic1 cars' or ./indices.rb elastic0 cars'

require 'net/http'
require 'webrick'

elastic_url='http://localhost:9200/'

Thread.new do
  # Redirect stderr to file instead console to supress web-server access logs console output
  $stderr = File.new('./access.log', 'w')
  $stderr.sync = true

  # run webserver stub, giving static txt file for any request
  server = WEBrick::HTTPServer.new(:Port => 9200, :DocumentRoot => [ARGV[0], ".txt"].join).start
end

puts 'Waiting 1 second for web-server thread to be started...'
sleep (1)
puts 'Trying to connect and get the list...'

uri = URI ( [ elastic_url, "cat/indices?v" ].join )
data = Net::HTTP.get(uri)

puts 'Got the list! Processing further...'

data.split("\n").grep(/ +open +[^ ]*#{ARGV[1]}/).each do |line|
  indice = line.split[2]
  #Thread.new do # uncomment if using new threads instead processes
  child_pid = fork do # comment if using new threads instead processes
    puts "Trying to close indice: #{indice}..."  
    uri = URI ( [ elastic_url, indice, '/close' ].join )
    puts "HTTP POST to uri: #{uri}"
    req = Net::HTTP::Post.new(uri)
    puts "Indice #{indice} is closed!"
  end  # comment if using new threads instead processes
  #end.join uncomment if using new threads instead processes
end
