# frozen_string_literal: true
require_relative 'service'

module OrcaApi
  class PrescriptionPrintService < Service
    def get_medical_fee(params)
      orca_api.call("/api21/medicalmodv31", body: {
        "medicalv3req1" => params,
      })
    end

    def medical_call(params)
      orca_api.call("/api21/medicalmodv32", body: {
        "medicalv3req2" => params,
      })
    end
  end
end
