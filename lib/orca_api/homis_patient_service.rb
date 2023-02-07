# frozen_string_literal: true

require_relative "service"

module OrcaApi
  class HomisPatientService < Service
    # https://www.orca.med.or.jp/receipt/tec/api/patientmod.html


    # 患者情報の登録
    def create(patient_information, patient_id: "*")

    end

    private

    def call(id, patient_information)
      
    end
  end
end