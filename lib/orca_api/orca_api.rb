require "uri"
require "net/http"
require "json"
require "securerandom"

require_relative "orca_api/ssl_client_authentication"
require_relative "orca_api/basic_authentication"

require_relative "result"

module OrcaApi
  # 日医標準レセプトソフト APIを呼び出すため低レベルインタフェースを提供するクラス
  class OrcaApi
    attr_accessor :host
    attr_accessor :authentication
    attr_accessor :port
    attr_writer :karte_uid
    attr_accessor :debug_output

    def self.underscore(name)
      name.
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        downcase
    end

    def initialize(host, authentication, port = 8000)
      @host = host
      @authentication = authentication
      @port = port
    end

    def karte_uid
      @karte_uid ||= SecureRandom.uuid
    end

    def call(path, params: {}, body: nil, http_method: :post)
      case http_method
      when :get
        request_class = Net::HTTP::Get
      when :post
        request_class = Net::HTTP::Post
      end

      query = params.merge(format: "json").map { |k, v|
        "#{k}=#{v}"
      }.join("&")

      req = request_class.new("#{path}?#{query}")

      if body
        req.body = body.to_json
      end

      http = Net::HTTP.new(@host, @port)

      if @debug_output
        http.set_debug_output(@debug_output)
      end

      [@authentication].flatten.each do |auth|
        auth.apply(http, req)
      end

      http.start { |h|
        res = h.request(req)
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
    )
    service_class_names.each do |name|
      s = underscore(name)

      require_relative s

      service_class = ::OrcaApi.const_get(name)
      define_method("new_#{s}") do
        service_class.new(self)
      end
    end
  end
end
