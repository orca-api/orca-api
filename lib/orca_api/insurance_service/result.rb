# coding: utf-8

require_relative "../result"

module OrcaApi
  class InsuranceService < Service
    # 保険・公費の種類を扱うサービスの処理の結果を表現するクラス
    class Result < ::OrcaApi::Result
      def insurance_information
        @body["Insurance_Information"]
      end
    end
  end
end
