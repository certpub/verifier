require 'config'
require 'rainbow'
require 'slop'


# CLI PARSER

opts = Slop.parse do |o|
  o.string '-m', '--mode', 'mode', default: 'production'
  o.string '-p', '--participant', 'participant identifier'
  o.string '--scheme', 'participant scheme', default: 'iso6523-actorid-upis'
  o.string '--locator', 'locator address'
  o.string '--locator-spec', 'locator specification', default: 'certpub-v1'
  o.string '--publisher', 'publisher address'
  o.string '--publisher-spec', 'publisher specification'
  o.string '--user-agent', 'user agent', default: 'CertPub/Verifier'
  o.bool '-h', '--help', 'Display help'
end


# CLI HELP

if opts[:help]
  puts opts
  exit
end


# CONFIG

Config.load_and_set_settings(Config.setting_files(File.join(__dir__, 'config'), opts[:mode]))


# LOAD APPLICATION

Dir[File.join(__dir__, 'lib', '*.rb')].sort.each { |file| require file }


# PARTICIPANT

if opts[:participant] == nil
  puts Rainbow("Participant identifier is not provided").red
  exit 1
end

participant = CertPub::Model::Participant::new opts[:participant], opts[:scheme]

puts Rainbow('Participant').blue.bright
puts "Identifier: #{participant.value}"
puts "Scheme: #{participant.scheme}"
puts "Full: #{participant} #{participant.valid? ? Rainbow("[OK]").green : Rainbow("[ERR]").red}"
puts


# CONTEXT

context = CertPub::Model::Context::new
context.opts = opts
context.home_folder = __dir__
context.issuers = CertPub::Service::Issuers::new context


# TODO: MORIBUS


# LOCATOR

locator_response = nil

if opts[:publisher] == nil
  # Find locator address
  locator_address = opts[:locator] != nil ? opts[:locator] : Settings.locator.url
  # Find specification metadata
  spec = Settings.spec.locator.filter { |spec| spec.id == opts[:locator_spec] }.first
  
  if spec
    # Perform discovery
    puts Rainbow("Locator: #{spec.name}").blue.bright
    locator_response = CertPub::Util::impl(spec.impl).send('perform', context, locator_address, participant)
    puts
  else
    # Implementation of specified specification was not found
    puts Rainbow("Implementation for locator specification with id '#{opts[:locator_spec]}' is unknown").red
    exit 1
  end

  if locator_response == nil
    # No response from locator
    exit 1
  end
end


# PUBLISHER

if locator_response
  locator_response.each do |key, address|
    Settings.spec.publisher.filter { |spec| spec.key == key }.each do |spec|
      puts Rainbow("Publisher: #{spec.name}").blue.bright
      CertPub::Util::impl(spec.impl).send('perform', context, address, participant)
      puts
    end
  end
end
