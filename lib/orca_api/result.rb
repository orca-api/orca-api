# coding: utf-8

require "ostruct"

module OrcaApi
  # 日レセAPIの呼び出し結果を扱うクラス
  class Result
    attr_reader :raw

    def initialize(raw)
      @raw = raw
      @body = raw.first[1]
    end

    def api_result
      @body["Api_Result"]
    end

    def ok?
      /\A0+\z/ =~ api_result ? true : false
    end

    def api_result_message
      @body["Api_Result_Message"]
    end

    def message
      "#{api_result_message}(#{api_result})"
    end
  end
end
