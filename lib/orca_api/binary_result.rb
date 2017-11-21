module OrcaApi
  # 画像データ取得APIのようなバイナリ形式の日レセAPIの呼び出し結果を扱うクラス
  #
  # @see OrcaApi::OrcaApi::ImageService
  class BinaryResult
    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    alias body raw

    def ok?
      true
    end

    def api_result
      "0"
    end

    def api_result_message
      "正常終了"
    end
  end
end
