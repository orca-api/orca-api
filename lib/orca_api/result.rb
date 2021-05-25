require "set"

module OrcaApi
  # 日レセAPIの呼び出し結果を扱うクラス
  class Result
    LOCKED_API_RESULT = Set.new(%w(E90 E9999))

    def self.trim_response(hash)
      result = {}
      hash.each do |k, v|
        result[k] = case v
                    when Hash
                      trim_response(v)
                    when Array
                      v.reverse_each.drop_while(&:empty?).reverse.map { |e| trim_response(e) }
                    else
                      v
                    end
      end
      result
    end

    def self.parse(raw)
      trim_response(JSON.parse(raw)).first[1]
    end

    # 深いパスのレスポンスボディに対するアクセサーを定義するメソッド
    #
    # @param [String, Symbol] name
    #   定義するメソッド名
    # @param [Array<String>] path
    #   レスポンスボディのパス
    # @return [Array<Array, Hash>]
    #   レスポンスボディ
    # @example
    #   class SomeResult < Result
    #     def_info :some_info, "Some_Information", "Some_Info"
    #   end
    #   res = SomeResult.new({
    #                          "someres" => {
    #                            "Some_Information" => {
    #                              "Some_Info" => [
    #                                { "Some_ID" => "foo" }, { "Some_ID" => "bar" }
    #                              ]
    #                            }
    #                          }
    #                        }.to_json)
    #   res.some_info
    #   # => [ { "Some_ID" => "foo" }, { "Some_ID" => "bar" } ]
    #   res = SomeResult.new({
    #                          "someres" => {
    #                          }
    #                        }.to_json)
    #   res.some_info
    #   # => []
    #
    def self.def_info(name, *path)
      define_method name do
        Array(body.dig(*path))
      end
    end

    attr_reader :raw

    def initialize(raw)
      @raw = raw
      @attr_names = body.keys.map { |key|
        [Client.underscore(key).to_sym, key]
      }.to_h
    end

    def body
      @body ||= self.class.parse(@raw)
    end

    def [](key)
      body[key]
    end

    # Api_Resultが00、0000、W00といった処理完了を示す値である場合にtrueを返す
    #
    # @return [Boolean]
    #   Api_Resultが処理完了を示す値である場合にtrueを返す
    def ok?
      /\AW?0+\z/.match? api_result
    end

    def warning?
      /\AW/.match? api_result
    end

    def locked?
      LOCKED_API_RESULT.include?(api_result)
    end

    def message
      "#{api_result_message}(#{api_result})"
    end

    def method_missing(symbol, *args)
      if (key = @attr_names[symbol])
        body[key]
      else
        super
      end
    end

    def respond_to_missing?(symbol, arg)
      if @attr_names.key?(symbol)
        true
      else
        super
      end
    end
  end
end
