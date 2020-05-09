require 'cgi'

module CertPub

  module Model

    # Simple representation of a process identifier
    class Process
      attr_accessor :value, :scheme

      def initialize(value, scheme)
        @value = value
        @scheme = scheme
      end

      def to_s
        "#{@scheme}::#{@value}"
      end

      def escaped
        CGI.escape(to_s)
      end

    end

  end

end