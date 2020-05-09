require 'nokogiri'
require 'openssl'
require 'base64'

module CertPub

  module Spec

    class PublisherV1Encryption

      def self.perform(context, address, participant)
        instance = self::new context, address, participant
        instance.listing
      end

      def initialize(context, address, participant)
        @context = context
        @client = CertPub::Util::RestClient address
        @participant = participant
      end

      def listing
        path = "api/v1/#{@participant.escaped}"

        puts "Address: #{@client.base_url}"
        puts "Path: #{path}"
        
        resp = @client.get(path)
        
        puts "Status: #{Rainbow(resp.status).cyan} #{verify(resp.status == 200)}"

        if resp.status == 200
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
          puts "Response: #{Rainbow(resp.body).red}"
        end
      end

      def single(process, role)
        puts Rainbow("  Process: #{process.scheme}::").blue + Rainbow(process.value).blue.bright + Rainbow(" @ #{role}").blue
        path = "api/v1/#{@participant.escaped}/#{process.escaped}/#{role}"

        puts "  Address: #{@client.base_url}"
        puts "  Path: #{path}"

        resp = @client.get(path)
        
        puts "  Status: #{Rainbow(resp.status).cyan} #{verify(resp.status == 200)}"

        if resp.status == 200
          xml = Nokogiri::XML(resp.body)

          xml_participant = xml.css('Process ParticipantIdentifier')
          res_participant = CertPub::Model::Participant::new xml_participant.text(), xml_participant.xpath('@scheme')
          puts "  Participant: #{Rainbow(res_participant).cyan} #{verify(@participant == res_participant)}"

          xml_process = xml.css('Process ProcessIdentifier')
          res_process = CertPub::Model::Process::new xml_process.text, xml_process.xpath('@scheme')
          puts "  Process: #{Rainbow(res_process).cyan} #{verify(process == res_process)}"

          puts "  Certificate:"
          xml.css('Certificate').each do |cert|
            certificate = OpenSSL::X509::Certificate.new Base64.decode64(cert.text)

            puts "  - Subject: #{Rainbow(certificate.subject).cyan}"
            puts "    Issuer: #{Rainbow(certificate.issuer).cyan}"
            puts "    Serialnumber: #{Rainbow(certificate.serial).cyan} #{verify(cert.xpath('@serialNumber').to_s == certificate.serial.to_s)}"
            puts "    Valid: #{Rainbow(certificate.not_before).cyan} => #{Rainbow(certificate.not_after).cyan}"
          end
        else
          puts "  Response: #{Rainbow(resp.body).red}"
        end
      end

      def verify(result)
        result ? Rainbow('[OK]').green : Rainbow('[ERR]').red
      end

    end

  end

end