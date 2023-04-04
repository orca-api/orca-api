# frozen_string_literal: true

require_relative "../service"

module OrcaApi
  class PatientService < Service
    class PatientSearchService < Service
      # https://www.orca.med.or.jp/receipt/tec/api/patientshimei.html

      # 患者情報の検索
      def search(params)
        Result.new(call(params))
      end

      private

        def call(params)
          req = { "patientlst3req" => params }

          orca_api.call("/api01rv2/patientlst3v2?class=01", body: req)
        end
    end
  end
end
