module OrcaApi
  # 日レセAPIの呼び出し結果を扱うクラス
  class Result
    LOCKED_API_RESULT = Set.new(%w(E90 E9999))

    def self.trim_response(hash)
      result = {}
      hash.each do |k, v|
        case v
        when Hash
          result[k] = trim_response(v)
        when Array
          found = false
          v.reverse.each do |v2|
            if !v2.empty?
              found = true
            end
            if found
              result[k] ||= []
              result[k].unshift(trim_response(v2))
            end
          end
        else
          result[k] = v
        end
      end
      result
    end

    def self.parse(raw)
      trim_response(JSON.parse(raw)).first[1]
    end

    attr_reader :raw

    def initialize(raw)
      @raw = raw
      @attr_names = body.keys.map { |key|
        [OrcaApi.underscore(key).to_sym, key]
      }.to_h
    end

    def body
      @body ||= self.class.parse(@raw)
    end

    def [](key)
      body[key]
    end

    def ok?
      /\A0+\z/ =~ api_result ? true : false
    end

    def locked?
      LOCKED_API_RESULT.include?(api_result)
    end

    def message
      "#{api_result_message}(#{api_result})"
    end

    def method_missing(symbol, *_)
      if (key = @attr_names[symbol])
        body[key]
      else
        super
      end
    end

    def respond_to_missing?(symbol, _)
      if @attr_names.key?(symbol)
        true
      else
        super
      end
    end
  end
end
