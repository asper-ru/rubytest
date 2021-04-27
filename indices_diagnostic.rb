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
puts '############# Go processing! ##############'
puts 'Process.pid, Process.ppid are:', Process.pid, Process.ppid
data.split("\n").grep(/ +open +[^ ]*#{ARGV[1]}/).each do |line|
  indice = line.split[2]
  
  child_pid = fork 
    
  if child_pid == 0 then next

  puts " -- Subprocess for #{indice} is started! 1..2..3.."
  puts "Trying to close indice: #{indice}..."  
  uri = URI ( [ elastic_url, indice, '/close' ].join )
  puts "HTTP POST to uri: #{uri}"
  req = Net::HTTP::Post.new(uri)
  sleep(5) # to catch process in the list by 'ps aux|grep ruby'
  puts "Indice #{indice} is closed!"
  puts " ---- Subprocess for #{indice} is finished! ..3..4..5!"

  break
end

  puts " == Processing #{indice}! 0..1..2..3..4..5.."
  sleep(10) # to give time to subprocesses to be finished correctly
  puts " ==== Processing #{indice}! 6..7..8..9..voila!"
  Process.waitall
end
