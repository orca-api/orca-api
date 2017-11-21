require_relative "result"

module OrcaApi
  # 日レセAPIの呼び出し結果のうち、帳票に関するものを扱うクラス
  class FormResult < Result
    def self.parse(raw)
      JSON.parse(raw)
    end
  end
end
