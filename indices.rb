#!/usr/bin/ruby
#
# Run script like './indices.rb elastic1 cars'

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

puts 'waiting 1 second for web-server thread to be started...'
sleep (1)
puts 'trying to connect and get the list'

uri = URI ( [ elastic_url, "cat/indices?v" ].join )
data = Net::HTTP.get(uri)

data.split("\n").grep(/ +open +[^ ]*#{ARGV[1]}/).each do |line|
  indice = line.split[2]
  puts (indice)
  Thread.new do
    puts "Closing indice: #{indice}..."  
    uri = URI ( [ elastic_url, indice, '/close' ].join )
    puts "HTTP POST to uri: #{uri}"
    puts Net::HTTP.post(uri)
  end.join
end
