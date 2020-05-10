require 'openssl'

module CertPub

  module Service

    class Issuers

      def initialize(context)
        @context = context
        @store = OpenSSL::X509::Store::new
      end

      def add_cert(cert)
        certificate = OpenSSL::X509::Certificate::new cert

        @store.add_cert certificate
      end

      def verify(cert)
        @context.zache.get(cert) do
          @store.verify(cert)
        end
      end

    end

  end

end