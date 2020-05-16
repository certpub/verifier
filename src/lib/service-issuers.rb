require 'tempfile'
require 'openssl'
require 'json'

module CertPub

  module Service

    class Issuers

      def initialize(context)
        @context = context
        @store = OpenSSL::X509::Store::new

        s = Settings.issuers

        client = CertPub::Util::RestClient context
        resp = client.get("https://api.github.com/repos/#{s.repo}/releases/latest")

        release = JSON.parse(resp.body)

        resp = client.get("https://github.com/#{s.repo}/releases/download/#{release['tag_name']}/certpub-#{s.id}-#{release['tag_name']}.pem")

        file = Tempfile.new('pem')
        file.write resp.body
        file.close

        @store.add_file(file.path)

        file.unlink
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