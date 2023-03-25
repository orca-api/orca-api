# frozen_string_literal: true

require_relative "service"

module OrcaApi
  module PatientSearchService < Service
    # https://www.orca.med.or.jp/receipt/tec/api/patientshimei.html

    # 患者情報の検索
    def search(params)
      Result.new(call(params))
    end

    private

    def call(params)
      req = { "patientlst3req" => params }

      orca_api.call("/orca12/patientsearchv2", body: req)
    end
  end
end