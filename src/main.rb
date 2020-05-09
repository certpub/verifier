require 'cgi'
require 'config'
require 'json'
require 'nokogiri'
require 'patron'
require 'rainbow'
require 'slop'

opts = Slop.parse do |o|
  o.string '-m', '--mode', 'mode', default: 'production'
  o.string '-p', '--participant', 'participant identifier', default: '0192:984851006'
  o.string '--scheme', 'participant scheme', default: 'iso6523-actorid-upis'
  o.string '--locator', 'locator address'
  o.string '--publisher', 'publisher address'
end

Config.load_and_set_settings(Config.setting_files("#{__dir__}/config", opts[:mode]))


participant = "#{opts[:scheme]}::#{opts[:participant]}"

puts Rainbow('Participant').blue
puts "Identifier: #{opts[:participant]}"
puts "Scheme: #{opts[:scheme]}"
puts "Full: #{participant}"
puts


locator = Patron::Session.new
locator.timeout = 10
locator.base_url = opts[:locator] != nil ? opts[:locator] : Settings.locator.url
locator.headers['User-Agent'] = 'CertPub/Verify'

lookup_path = "lookup/v2/#{CGI.escape participant}"

puts Rainbow('Locator').blue
if opts['publisher'] != nil
  puts Rainbow('Skipped...').green
  puts

  publisher_url = opts['publisher']
else
  puts "Address: #{locator.base_url}"
  puts "Path: #{lookup_path}"

  resp = locator.get(lookup_path)

  if resp.status == 200
    locator_response = JSON.parse(resp.body)

    puts "Status: #{Rainbow(resp.status).green}"
    puts "Response:"
    locator_response.each do |k,v|
      puts "  #{Rainbow(k).green}: #{v}"
    end
    puts

    publisher_url = locator_response['difi-bcp-v1']
  else
    puts "Status: #{Rainbow(resp.status).red}"
    puts "Response: #{Rainbow(resp.body).red}"
    puts
    puts Rainbow('Fail: Participant not found in locator.').red
    exit 1
  end
end

publisher = Patron::Session.new
publisher.timeout = 10
publisher.base_url = publisher_url
publisher.headers['User-Agent'] = 'CertPub/Verify'

path = "api/v1/#{CGI.escape participant}"

puts Rainbow('Publisher, encryption').blue
puts "Address: #{publisher.base_url}"
puts "Path: #{path}"

resp = publisher.get(path)

if resp.status == 200
  puts "Status: #{Rainbow(resp.status).green}"
  puts "Response:"

  xml = Nokogiri::XML(resp.body)
  xml.css("Participant ProcessReference").each do |e|
    puts "  #{e.xpath('@scheme')}::#{e.text} @ #{e.xpath('@role')}"
  end

  puts
else
  puts "Status: #{Rainbow(resp.status).red}"
  puts "Response: #{Rainbow(resp.body).red}"
  puts
end


path = "api/v1/sig/#{CGI.escape participant}"

puts Rainbow('Publisher, signing').blue
puts "Address: #{publisher.base_url}"
puts "Path: #{path}"

resp = publisher.get(path)

if resp.status == 200
  puts "Status: #{Rainbow(resp.status).green}"
  puts "Response:"

  xml = Nokogiri::XML(resp.body)
  xml.css("Participant ProcessReference").each do |e|
    puts "  #{e.xpath('@qualifier')}::#{e.text} @ #{e.xpath('@role')}"
  end

  puts
else
  puts "Status: #{Rainbow(resp.status).red}"
  puts "Response: #{Rainbow(resp.body).red}"
  puts
end
