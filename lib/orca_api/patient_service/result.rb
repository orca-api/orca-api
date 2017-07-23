# coding: utf-8

require_relative "../result"

module OrcaApi
  class PatientService
    # 汎用的な患者情報を扱う処理の結果を表現するクラス
    class Result < ::OrcaApi::Result
      def patient_information
        @body["Patient_Information"]
      end
    end
  end
end
