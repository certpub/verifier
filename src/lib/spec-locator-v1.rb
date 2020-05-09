require 'json'
require 'patron'

module CertPub

  module Spec

    module LocatorV1

      def self.perform(address, participant)
        client = CertPub::Util::RestClient address
        path = "lookup/v2/#{participant.escaped}"

        puts "Address: #{client.base_url}"
        puts "Path: #{path}"

        # Fetch from locator
        resp = client.get(path)

        puts "Status: #{Rainbow(resp.status).cyan} #{verify(resp.status == 200)}"

        if resp.status == 200
          response = JSON.parse(resp.body)

          puts "Response:"
          response.each do |k,v|
            if Settings.spec.publisher.filter { |spec| spec.key = k } 
              puts Rainbow("  #{k}: #{v}").cyan
            else
              puts "  #{k}: #{v}"
            end
          end

          return response
        else
          puts "Response: #{Rainbow(resp.body).red}"

          return nil
        end
      end

      def self.verify(result)
        result ? Rainbow('[OK]').green : Rainbow('[ERR]').red
      end

    end

  end

end