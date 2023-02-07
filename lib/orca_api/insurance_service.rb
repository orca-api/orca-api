require_relative "service"

module OrcaApi
  # 保険・公費の種類を扱うサービスを表現したクラス
  class InsuranceService < Service
    # 保険の種類と補助区分、公費の種類の一覧の取得
    def list(base_date = "")
      api_path = "/api01rv2/insuranceinf1v2"
      req_name = "insuranceinfreq"

      body = {
        req_name => {
          "Request_Number" => "01",
          "Base_Date" => base_date,
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end
  end
end
