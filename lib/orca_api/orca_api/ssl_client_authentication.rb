# coding: utf-8

require "openssl"

module OrcaApi
  class OrcaApi
    # SSLクライアント認証を表現するクラス
    class SslClientAuthentication
      attr_accessor :ca_file
      attr_accessor :cert_path
      attr_accessor :key_path

      def initialize(ca_file, cert_path, key_path)
        @ca_file = ca_file
        @cert_path = cert_path
        @key_path = key_path
      end

      def cert
        OpenSSL::X509::Certificate.new(File.read(cert_path))
      end

      def key
        OpenSSL::PKey::RSA.new(File.read(key_path))
      end

      def apply(http, _request)
        http.use_ssl = true
        http.ca_file = ca_file
        http.cert = cert
        http.key = key
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end
  end
end
