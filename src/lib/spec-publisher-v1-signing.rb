require 'nokogiri'

module CertPub

  module Spec

    module PublisherV1Signing

      def self.perform(address, participant)
        client = CertPub::Util::RestClient address

        path = "api/v1/sig/#{participant.escaped}"

        puts "Address: #{client.base_url}"
        puts "Path: #{path}"

        resp = client.get(path)

        if resp.status == 200
          puts "Status: #{Rainbow(resp.status).green.bright}"
          puts "Response:"

          xml = Nokogiri::XML(resp.body)
          xml.css("Participant ProcessReference").sort_by(&:text).each do |e|
            puts Rainbow("  #{e.xpath('@qualifier')}::").cyan + Rainbow(e.text).cyan.bright + Rainbow(" @ #{e.xpath('@role')}").cyan
          end
        else
          puts "Status: #{Rainbow(resp.status).red.bright}"
          puts "Response: #{Rainbow(resp.body).red}"
        end
      end

    end

  end

end