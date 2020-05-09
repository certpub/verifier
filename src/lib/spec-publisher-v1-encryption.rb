require 'nokogiri'
require 'openssl'
require 'base64'

module CertPub

  module Spec

    class PublisherV1Encryption

      def self.perform(address, participant)
        instance = self::new address, participant
        instance.listing
      end

      def initialize(address, participant)
        @client = CertPub::Util::RestClient address
        @participant = participant
      end

      def listing
        path = "api/v1/#{@participant.escaped}"

        puts "Address: #{@client.base_url}"
        puts "Path: #{path}"
        
        resp = @client.get(path)
        
        if resp.status == 200
          puts "Status: #{Rainbow(resp.status).green}"
        
          xml = Nokogiri::XML(resp.body)
          puts "Process references: #{Rainbow(xml.css("Participant ProcessReference").count).cyan}"
          puts

          xml.css("Participant ProcessReference").sort_by(&:text).each do |e|
            process = CertPub::Model::Process::new e.text, e.xpath('@scheme')
            role = e.xpath('@role')

            single process, role
            puts
          end
        else
          puts "Status: #{Rainbow(resp.status).red.bright}"
          puts "Response: #{Rainbow(resp.body).red}"
        end
      end

      def single(process, role)
        puts Rainbow("  Process: #{process.scheme}::").blue + Rainbow(process.value).blue.bright + Rainbow(" @ #{role}").blue
        path = "api/v1/#{@participant.escaped}/#{process.escaped}/#{role}"

        puts "  Address: #{@client.base_url}"
        puts "  Path: #{path}"

        resp = @client.get(path)
        
        if resp.status == 200
          puts "  Status: #{Rainbow(resp.status).green}"
        
          xml = Nokogiri::XML(resp.body)

          xml_participant = xml.css('Process ParticipantIdentifier')
          res_participant = CertPub::Model::Participant::new xml_participant.text(), xml_participant.xpath('@scheme')
          puts "  Participant: #{Rainbow(res_participant).color(@participant == res_participant ? :green : :red)}"

          xml_process = xml.css('Process ProcessIdentifier')
          res_process = CertPub::Model::Process::new xml_process.text, xml_process.xpath('@scheme')
          puts "  Process: #{Rainbow(res_process).color(process == res_process ? :green : :red)}"

          puts "  Certificate:"
          xml.css('Certificate').each do |cert|
            certificate = OpenSSL::X509::Certificate.new Base64.decode64(cert.text)

            puts "  - Subject: #{Rainbow(certificate.subject).cyan}"
            puts "    Issuer: #{Rainbow(certificate.issuer).cyan}"
            puts "    Serialnumber: #{Rainbow(certificate.serial).color(cert.xpath('@serialNumber').to_s == certificate.serial.to_s ? :green : :red)}"
            puts "    Expire: #{Rainbow(certificate.not_after).cyan}"
          end
        else
          puts "  Status: #{Rainbow(resp.status).red.bright}"
          puts "  Response: #{Rainbow(resp.body).red}"
        end
      end

    end

  end

end