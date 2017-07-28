# coding: utf-8

module OrcaApi
  # 各種情報を扱うサービスを表現したクラス
  class Service
    attr_reader :orca_api

    def initialize(orca_api)
      @orca_api = orca_api
    end
  end
end
