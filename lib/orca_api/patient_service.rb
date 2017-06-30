# coding: utf-8

module OrcaApi
  # 患者情報を扱うサービスを表現したクラス
  class PatientService
    attr_reader :orca_api

    def initialize(orca_api)
      @orca_api = orca_api
    end
  end
end
