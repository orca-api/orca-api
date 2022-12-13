# frozen_string_literal: true

require_relative "service"

module OrcaApi
  # 点数マスタ一括取得
  #
  # @see https://www.orcamo.co.jp/api-council/members/samples/?dl=haori/orca51_medicationmasterlstv3.pdf
  # @see https://www.orcamo.co.jp/api-council/members/samples/?dl=haori/orca51_medicationmasterlstv3_err.pdf
  class MedicationMasterListService < Service
    def list(params)
      Result.new(call(params))
    end

    private

    def call(params)
      body = {
        "medication_masterlstv3req" => params
      }

      orca_api.call("/orca51/medicationmasterlstv3", body: body)
    end
  end
end
