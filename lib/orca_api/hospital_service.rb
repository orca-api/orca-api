# frozen_string_literal: true
require_relative 'service'

module OrcaApi
  class HospitalService < Service
    # 医療機関基本情報一覧の取得
    #
    # @param [String] base_date
    #   基準日。YYYY-mm-dd形式。
    #
    # @return [OrcaApi::Result]
    #   https://www.orca.med.or.jp/receipt/tec/api/systemkanri.html#response3
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/systemkanri.html
    def list(base_date = "")
      api_path = "/api01rv2/system01lstv2"
      req_name = "system01_managereq"

      body = {
        req_name => {
          "Request_Number" => "04",
          "Base_Date" => base_date,
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end
  end
end
