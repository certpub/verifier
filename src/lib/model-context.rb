require 'zache'

module CertPub

  module Model

    class Context
      attr_accessor :opts, :home_folder, :issuers, :zache

      def initialize
        @zache = Zache.new
      end
    end

  end

end