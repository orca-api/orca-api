require_relative "service"

module OrcaApi
  # ドクターコードを扱うサービスを表現したクラス
  class PhysicianService < Service
    # ドクターコード一覧の取得
    def list(base_date = "")
      api_path = "/api01rv2/system01lstv2"
      req_name = "system01_managereq"

      body = {
        req_name => {
          "Request_Number" => "02",
          "Base_Date" => base_date,
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end
  end
end
