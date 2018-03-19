require_relative "service"

module OrcaApi
  # 受付業務を扱うクラス
  class AcceptanceService < Service
    # listメソッドの戻り値クラス
    class ListResult < Result
      def list
        Array(body["Acceptlst_Information"])
      end
    end

    # https://www.orca.med.or.jp/receipt/tec/api/acceptancelst.html
    def list(klass: "03", base_date: nil, department_code: nil, physician_code: nil, medical_information: nil)
      api_path = "/api01rv2/acceptlstv2"
      req_name = "acceptlstreq"

      params = {
        class: klass
      }

      request = {}
      request["Acceptance_Date"] = base_date if base_date
      request["Department_Code"] = department_code if department_code
      request["Physician_Code"] = physician_code if physician_code
      request["Medical_Information"] = medical_information if medical_information

      body = {
        req_name => request
      }

      ListResult.new(orca_api.call(api_path, params: params, body: body))
    end

    # https://www.orca.med.or.jp/receipt/tec/api/acceptmod.html
    def create(acceptance)
      req = acceptance.merge(
        "Request_Number" => "01"
      )
      call_acceptance(req)
    end

    # 新規患者の受付更新(患者番号設定)
    #
    # 患者氏名のみを指定して登録した受付情報に患者番号を設定する。
    #
    # @param [String] acceptance_id
    #   受付ID
    # @param [Hash] acceptance
    #   * "Acceptance_Date" (String)
    #     受付日付。YYYY-mm-dd形式。
    #   * "Acceptance_Time" (String)
    #     受付時間。HH:MM:SS形式。
    #   * "Patient_ID" (String)
    #     患者番号
    #   * "Department_Code" (String)
    #     診療科コード。
    #     システム管理マスタの診療科目情報の診療科コードを参照。
    #   * "Physician_Code" (String)
    #     ドクターコード。
    #   * "Medical_Information" (String)
    #     診療内容区分。
    #     システム管理マスタの診療内容情報の診療内容コードを参照。
    #     診療内容コード例)01:診察１、02:薬のみ、03:注射のみ、04:検査のみ、05:リハビリテーション、
    #     06:健康診断、07:予防注射、99:該当なし
    #   * "HealthInsurance_Information" (Hash)
    #     保険組合せ情報
    #     * "Insurance_Combination_Number" (String)
    #       保険組合せ番号
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/acceptmod.html
    def update(acceptance_id, acceptance)
      req = acceptance.merge(
        "Request_Number" => "03",
        "Acceptance_Id" => acceptance_id
      )
      call_acceptance(req)
    end

    # https://www.orca.med.or.jp/receipt/tec/api/acceptmod.html
    def destroy(acceptance_id, patient_id)
      req = {
        "Request_Number" => "02",
        "Acceptance_Id" => acceptance_id,
        "Patient_ID" => patient_id
      }
      call_acceptance(req)
    end

    def new_builder
      AcceptanceBuilder.new
    end

    # AcceptanceService#{create,update}の引数を生成するクラス
    #
    #     AcceptanceBuilder.new.accept_at(Time.now).patient_id('00001').insurance_combination_number('01').to_h
    #     # => { "Acceptance_Date" => "YYYY-MM-DD", "Acceptance_Time" => "HH:MM:SS", ... }
    #
    class AcceptanceBuilder
      def initialize
        @data = {}
        @health_insurance = {}
      end

      def accept_at(accept_at = Time.now)
        @data['Acceptance_Date'] = accept_at.strftime("%F")
        @data['Acceptance_Time'] = accept_at.strftime("%T")
        self
      end

      %w[Patient_ID Department_Code Physician_Code Medical_Information].each do |name|
        define_method name.downcase do |value|
          @data[name] = value
          self
        end
      end

      def insurance_combination_number(value)
        @health_insurance['Insurance_Combination_Number'] = value
        self
      end

      def to_h
        @data.merge('HealthInsurance_Information' => @health_insurance)
      end
    end

    private

    def call_acceptance(req)
      Result.new(orca_api.call("/orca11/acceptmodv2", body: { "acceptreq" => req }))
    end
  end
end
