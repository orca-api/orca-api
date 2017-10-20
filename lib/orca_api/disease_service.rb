require_relative "service"

module OrcaApi
  # 患者の病名情報を扱うサービスを表現したクラス
  class DiseaseService < Service
    # 患者の病名情報の取得
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/disease.html
    def get(params)
      body = {
        "disease_inforeq" => params,
      }
      Result.new(orca_api.call("/api01rv2/diseasegetv2", params: { "class" => "01" }, body: body))
    end

    # 患者の病名情報の登録・更新・削除
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/diseasemod2.html
    def update(params)
      body = {
        "diseasereq" => params,
      }
      Result.new(orca_api.call("/orca22/diseasev3", body: body))
    end
  end
end
