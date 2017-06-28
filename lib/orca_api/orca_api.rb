# coding: utf-8

require "uri"
require "net/http"
require "json"

module OrcaApi
  # 日医標準レセプトソフト APIを呼び出すため低レベルインタフェースを提供するクラス
  class OrcaApi
    attr_accessor :url
    attr_accessor :basic_authentication
    attr_accessor :debug_output

    def initialize(options = {})
      @url = options[:url]
      @basic_authentication = options[:basic_authentication]
      @debug_output = options[:debug_output]
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

      req.basic_auth(*basic_authentication)

      if !body.empty?
        req.body = body.to_json
      end

      u = URI.parse(@url)
      http = Net::HTTP.new(u.host, u.port)

      if @debug_output
        http.set_debug_output(@debug_output)
      end

      http.start { |h|
        res = h.request(req)
        JSON.parse(res.body)
      }
    end
  end
end
