# coding: utf-8

require "uri"
require "net/http"
require "json"
require_relative "orca_api/ssl_client_authentication"
require_relative "orca_api/basic_authentication"

module OrcaApi
  # 日医標準レセプトソフト APIを呼び出すため低レベルインタフェースを提供するクラス
  class OrcaApi
    attr_accessor :host
    attr_accessor :authentication
    attr_accessor :port
    attr_accessor :debug_output

    def initialize(host, authentication, port = 8000)
      @host = host
      @authentication = authentication
      @port = port
    end

    def call(path, params: {}, body: {}, http_method: :post)
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

      if !body.empty?
        req.body = body.to_json
      end

      http = Net::HTTP.new(@host, @port)

      if @debug_output
        http.set_debug_output(@debug_output)
      end

      @authentication.apply(http, req)

      http.start { |h|
        res = h.request(req)
        JSON.parse(res.body)
      }
    end
  end
end
