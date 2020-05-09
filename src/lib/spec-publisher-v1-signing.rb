require 'nokogiri'

module CertPub

  module Spec

    class PublisherV1Signing

      def self.perform(address, participant)
        instance = self::new address, participant
        instance.listing_current
      end

      def initialize(address, participant)
        @client = CertPub::Util::RestClient address
        @participant = participant
      end

      def listing_current
        path = "api/v1/sig/#{@participant.escaped}"

        puts "Address: #{@client.base_url}"
        puts "Path: #{path}"

        resp = @client.get(path)

        if resp.status == 200
          puts "Status: #{Rainbow(resp.status).green.bright}"

          xml = Nokogiri::XML(resp.body)
          puts "Process references: #{Rainbow(xml.css("Participant ProcessReference").count).cyan}"
          puts

          xml.css("Participant ProcessReference").sort_by(&:text).each do |e|
            process = CertPub::Model::Process::new e.text, e.xpath('@qualifier')
            role = e.xpath('@role')
            
            single_current process, role
            puts
          end
        else
          puts "Status: #{Rainbow(resp.status).red.bright}"
          puts "Response: #{Rainbow(resp.body).red}"
        end
      end

      def single_current(process, role)
        puts Rainbow("  Process: #{process.scheme}::").blue + Rainbow(process.value).blue.bright + Rainbow(" @ #{role}").blue
        path = "api/v1/sig/#{@participant.escaped}/#{process.escaped}/#{role}"

        puts "  Address: #{@client.base_url}"
        puts "  Path: #{path}"

        resp = @client.get(path)
        
        if resp.status == 200
          puts "  Status: #{Rainbow(resp.status).green.bright}"
        
          xml = Nokogiri::XML(resp.body)
        else
          puts "  Status: #{Rainbow(resp.status).red.bright}"
          puts "  Response: #{Rainbow(resp.body).red}"
        end
      end

    end

  end

end