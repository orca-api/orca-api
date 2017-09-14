# coding: utf-8

require "uri"
require "net/http"
require "json"
require "securerandom"

require_relative "orca_api/ssl_client_authentication"
require_relative "orca_api/basic_authentication"

require_relative "result"

require_relative "patient_service"
require_relative "insurance_service"
require_relative "department_service"
require_relative "physician_service"
require_relative "medical_practice_service"
require_relative "acceptance_service"
require_relative "disease_service"

module OrcaApi
  # 日医標準レセプトソフト APIを呼び出すため低レベルインタフェースを提供するクラス
  class OrcaApi
    attr_accessor :host
    attr_accessor :authentication
    attr_accessor :port
    attr_writer :karte_uid
    attr_accessor :debug_output

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

    factory_methods = [
      ["new_patient_service", PatientService],
      ["new_insurance_service", InsuranceService],
      ["new_department_service", DepartmentService],
      ["new_physician_service", PhysicianService],
      ["new_medical_practice_service", MedicalPracticeService],
      ["new_acceptance_service", AcceptanceService],
      ["new_disease_service", DiseaseService],
    ]
    factory_methods.each do |name, klass|
      define_method(name) do
        klass.new(self)
      end
    end
  end
end
