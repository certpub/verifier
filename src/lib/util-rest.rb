require 'patron'

module CertPub

  module Util

    # Method simply wrapping creation of a Patron session with some defaults
    def self.RestClient(context, base_url = nil)
      session = Patron::Session.new
      session.timeout = 10
      session.base_url = base_url
      session.headers['User-Agent'] = context.opts[:user_agent]

      session
    end

  end

end