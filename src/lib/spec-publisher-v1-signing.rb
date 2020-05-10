require 'date'
require 'nokogiri'

module CertPub

  module Spec

    class PublisherV1Signing

      def self.perform(context, address, participant)
        instance = self::new context, address, participant
        instance.listing
        instance.listing true
      end

      def initialize(context, address, participant)
        @context = context
        @client = CertPub::Util::RestClient context, address
        @participant = participant

        @xsd = xsd = Nokogiri::XML::Schema(File.open(File.join(context.home_folder, 'xsd/publisher/certpub-signing-v1/certpub-publisher-v1-signing-1.0.xsd')))
      end

      def listing(historic = false)
        path = "api/v1/sig/#{historic ? 'historic/' : ''}#{@participant.escaped}"

        puts "Address: #{@client.base_url}"
        puts "Path: #{path}"

        resp = @client.get(path)

        puts "Status: #{Rainbow(resp.status).cyan} #{verify(resp.status == 200)}"

        if resp.status == 200
          xml = Nokogiri::XML(resp.body)

          validation = @xsd.validate(xml)
          puts "Document validation #{verify(validation.count == 0)}"
          validation.each do |error|
            puts "- #{Rainbow(error.message).red}"
          end

          xml_participant = xml.css('Participant ParticipantIdentifier')
          res_participant = CertPub::Model::Participant::new xml_participant.text(), xml_participant.xpath('@qualifier')
          puts "Participant: #{Rainbow(res_participant).cyan} #{verify(@participant == res_participant)}"

          xml_timestamp = xml.css('Participant Timestamp').text
          puts "Timestamp: #{Rainbow(xml_timestamp).cyan}"

          puts "Process references: #{Rainbow(xml.css("Participant ProcessReference").count).cyan}"
          puts

          xml.css("Participant ProcessReference").sort_by(&:text).each do |e|
            process = CertPub::Model::Process::new e.text, e.xpath('@qualifier')
            role = e.xpath('@role')
            
            single process, role, historic
            puts
          end
        else
          puts "Response: #{Rainbow(resp.body).red}"
        end
      end

      def single(process, role, historic = false)
        puts Rainbow("  Process: #{process.scheme}::").blue + Rainbow(process.value).blue.bright + Rainbow(" @ #{role}").blue
        path = "api/v1/sig/#{historic ? 'historic/' : ''}#{@participant.escaped}/#{process.escaped}/#{role}"

        puts "  Address: #{@client.base_url}"
        puts "  Path: #{path}"

        resp = @client.get(path)

        puts "  Status: #{Rainbow(resp.status).cyan} #{verify(resp.status == 200)}"
        
        if resp.status == 200
          xml = Nokogiri::XML(resp.body)

          validation = @xsd.validate(xml)
          puts "  Document validation #{verify(validation.count == 0)}"
          validation.each do |error|
            puts "  - #{Rainbow(error.message).red}"
          end

          xml_participant = xml.css('Process ParticipantIdentifier')
          res_participant = CertPub::Model::Participant::new xml_participant.text(), xml_participant.xpath('@qualifier')
          puts "  Participant: #{Rainbow(res_participant).cyan} #{verify(@participant == res_participant)}"

          xml_process = xml.css('Process ProcessIdentifier')
          res_process = CertPub::Model::Process::new xml_process.text, xml_process.xpath('@qualifier')
          puts "  Process: #{Rainbow(res_process).cyan} #{verify(process == res_process)}"

          res_role = xml.css('Process Role').text.to_s
          puts "  Role: #{Rainbow(res_role).cyan} #{verify(res_role == role.to_s)}"

          if historic
            res_date = xml.css('Process Timestamp').text
            puts "  Timestamp: #{Rainbow(res_date).cyan}"
          else
            res_date = xml.css('Process Date').text
            puts "  Date: #{Rainbow(res_date).cyan} #{verify(Date.parse(res_date) == Time.now.utc.to_date)}"
          end

          puts "  Certificate:"
          xml.css('Certificate').each do |cert|
            certificate = OpenSSL::X509::Certificate.new Base64.decode64(cert.css('Binary').text)

            puts "  - Subject: #{Rainbow(certificate.subject).cyan} #{verify(@context.issuers.verify certificate)}"
            puts "    Issuer: #{Rainbow(certificate.issuer).cyan}"
            puts "    Serialnumber: #{Rainbow(certificate.serial).cyan} #{verify(cert.xpath('@serialNumber').to_s == certificate.serial.to_s)}"
            puts "    Valid: #{Rainbow(certificate.not_before).cyan} => #{Rainbow(certificate.not_after).cyan}"
            puts "    Interval:"

            cert.css('Interval').each do |interval|
              from = interval.xpath('@from').to_s
              time_from = DateTime.parse(from)

              if !interval.xpath('@to').empty?
                to = interval.xpath('@to')
                pp to
                time_to = DateTime.parse(to.to_s)

                puts "    - #{Rainbow(from).cyan} #{verify(time_from => certificate.not_before)} => #{Rainbow(to).cyan} #{verify(time_to <= certificate.not_after)}"
              else
                puts "    - #{Rainbow(from).cyan} #{verify(time_from => certificate.not_before)} => Future"
              end
            end
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