require "net/http"

module OrcaApi
  # エラーを表現するクラス
  class Error < RuntimeError
  end

  # HTTP通信時に発生したエラーを表現するクラス
  class HttpError < Error
    attr_reader :response # エラーが発生したHTTP通信のNet::HTTPResponseオブジェクト

    def initialize(response)
      @response = response
      super("#{response.message} (#{response.code})")
    end
  end
end
