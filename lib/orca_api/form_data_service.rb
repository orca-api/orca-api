# coding: utf-8

require_relative "service"
require_relative "result"

module OrcaApi
  # 帳票データAPI
  #
  # @see https://www.orca.med.or.jp/receipt/tec/push-api/report_data_api.html
  # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/push-api/1.api_information.pdf 帳票データ取得APIについて
  class FormDataService < Service
    # 帳票データAPIの呼び出し結果を扱うクラス
    class Result < Result
      def initialize(raw)
        @body = @raw = raw
        @attr_names = @body.keys.map { |key|
          [self.class.json_name_to_attr_name(key).to_sym, key]
        }.to_h
      end
    end

    def get(data_id)
      Result.new(
        orca_api.call("/api01rv2/formdatagetv2",
                      body: {
                        "data" => {
                          "Data_ID" => data_id
                        }
                      })
      )
    end
  end
end
