require 'cgi'

module CertPub

  module Model

    # Simple representation of a participant identifier
    class Participant
      attr_accessor :value, :scheme

      def initialize(value, scheme)
        @value = value.to_s.strip
        @scheme = scheme.to_s.strip
      end

      def to_s
        "#{@scheme}::#{@value}"
      end

      def escaped
        CGI.escape(to_s)
      end

      def ==(o)
        o.class == self.class && o.to_s == to_s
      end

    end

  end

end