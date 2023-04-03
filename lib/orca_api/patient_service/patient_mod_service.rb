# frozen_string_literal: true

require_relative "../service"

module OrcaApi
  class PatientService < Service
    class PatientModService < Service
      # https://www.orca.med.or.jp/receipt/tec/api/patientmod.html

      # 患者情報の登録
      def create(patient)
        Result.new(call(patient, "01"))
      end

      def update(patient)
        Result.new(call(patient, "02"))
      end

      private

        def call(patient, klass)
          req = { "patientmodreq" => patient }

          orca_api.call("/orca12/patientmodv2?class=#{klass}", body: req)
        end
    end
  end
end
