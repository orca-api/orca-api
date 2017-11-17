require "uri"
require "net/http"
require "json"
require "securerandom"

require_relative "result"
require_relative "form_result"

module OrcaApi
  # 日医標準レセプトソフト APIを呼び出すため低レベルインタフェースを提供するクラス
  class OrcaApi
    attr_accessor :host
    attr_accessor :port
    attr_accessor :user
    attr_accessor :password
    attr_accessor :use_ssl
    attr_accessor :ca_file
    attr_accessor :ca_path
    attr_accessor :verify_mode
    attr_accessor :cert
    attr_accessor :key
    attr_writer :karte_uid
    attr_accessor :debug_output

    def self.underscore(name)
      name.
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        downcase
    end

    def initialize(uri, options = {})
      uri = URI.parse(uri)
      @host = uri.host
      @port = uri.port
      @user = uri.user || options[:user]
      @password = uri.password || options[:password]
      @use_ssl = uri.scheme == 'https' || options[:use_ssl]
      if @use_ssl
        extract_ssl_options(options.fetch(:ssl))
      end
    end

    def karte_uid
      @karte_uid ||= SecureRandom.uuid
    end

    def call(path, params: {}, body: nil, http_method: :post)
      req = make_request(http_method, path, params, body)
      new_http.start { |http|
        res = http.request(req)
        JSON.parse(res.body)
      }
    end

    service_class_names = %w(
      PatientService
      InsuranceService
      DepartmentService
      PhysicianService
      MedicalPracticeService
      AcceptanceService
      DiseaseService
      FormDataService
      IncomeService
      PrintService
    )
    service_class_names.each do |name|
      s = underscore(name)

      require_relative s

      service_class = ::OrcaApi.const_get(name)
      define_method("new_#{s}") do
        service_class.new(self)
      end
    end

    private

    def extract_ssl_options(ssl)
      @ca_file = ssl[:ca_file]
      @ca_path = ssl[:ca_path]

      @verify_mode = ssl.fetch(:verify_mode) do
        if ssl.fetch(:verify, true)
          OpenSSL::SSL::VERIFY_PEER
        else
          OpenSSL::SSL::VERIFY_NONE
        end
      end

      if (p12 = ssl[:p12])
        @cert = p12.certificate
        @key = p12.key
      else
        @cert = ssl[:cert]
        @key = ssl[:key]
      end
    end

    def new_http
      http = Net::HTTP.new(@host, @port)

      if @use_ssl
        http.use_ssl = true
        if @cert
          http.cert = @cert
        end
        if @key
          http.key = @key
        end
        if @ca_file
          http.ca_file = @ca_file
        end
        if @ca_path
          http.ca_path = @ca_path
        end
        if @verify_mode
          http.verify_mode = @verify_mode
        end
      end

      if @debug_output
        http.set_debug_output(@debug_output)
      end

      http
    end

    def make_request(http_method, path, params, body)
      case http_method
      when :get
        request_class = Net::HTTP::Get
      when :post
        request_class = Net::HTTP::Post
      end

      query = URI.encode_www_form(params.merge(format: "json"))

      req = request_class.new("#{path}?#{query}")

      req.basic_auth(@user, @password)

      if body
        req.body = body.to_json
      end

      req
    end
  end
end
