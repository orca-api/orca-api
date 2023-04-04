# frozen_string_literal: true

require_relative "service"

module OrcaApi
  # 患者情報を扱うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v031.pdf
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v031_err.pdf
  class PatientService < Service
    # 患者情報の登録の結果を表現するクラス
    class CreateResult < ::OrcaApi::Result
      def duplicated_patient_candidates
        body["Patient2_Information"] || []
      end
    end

    # 患者情報の登録
    #
    # @param [Hash] patient_information
    #   登録する患者情報。
    #   全角項目で（半角全角変換）を記載している項目は半角文字を全角文字へ変換します。拡張文字は■に変換します。
    #   * "WholeName" (String)
    #     漢字氏名/50/必須/全角２５文字
    #   * "WholeName_inKana" (String)
    #     カナ氏名/50/必須/全角２５文字（半角全角変換）
    #   * "BirthDate" (String)
    #     生年月日/10/必須
    #   * "Sex" (String)
    #     性別/1/1：男、2：女
    #   * "HouseHolder_WholeName" (String)
    #     世帯主名称/50/全角２５文字
    #   * "Relationship" (String)
    #     続柄/30/全角１５文字（半角全角変換）
    #   * "Occupation" (String)
    #     職業/20/全角１５文字（半角全角変換）
    #   * "NickName" (String)
    #     通称名称/50/全角２５文字
    #   * "CellularNumber" (String)
    #     携帯電話番号/15/半角
    #   * "FaxNumber" (String)
    #     15/半角
    #   * "EmailAddress" (String)
    #     メールアドレス/50
    #   * "Home_Address_Information" (Hash)
    #     自宅情報
    #     * "Address_ZipCode" (String)
    #       郵便番号/7/半角。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress1" (String)
    #       住所１/100/全角５０文字（半角全角変換）。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress2" (String) 住所２（番地番号）/100/全角５０文字（半角全角変換）
    #     * "PhoneNumber1" (String) 自宅電話番号/15/半角
    #     * "PhoneNumber2" (String) 連絡先電話番号/15/半角
    #   * "WorkPlace_Information" (Hash)
    #     勤務先情報
    #     * "WholeName" (String) 勤務先名称/50
    #     * "Address_ZipCode" (String)
    #       郵便番号/7/半角。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress1" (String)
    #       住所１/100/全角５０文字（半角全角変換）。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress2" (String) 住所２（番地番号）/100/全角５０文字（半角全角変換）
    #     * "PhoneNumber" (String) 勤務先電話番号/15/半角
    #   * "Contact_Information" (Hash)
    #     連絡先情報
    #     * "WholeName" (String) 連絡先名/50/全角２５文字（半角全角変換）
    #     * "Relationship" (String) 連絡先続柄/30/全角１５文字（半角全角変換）
    #     * "Address_ZipCode" (String)
    #       郵便番号/7/半角。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress1" (String)
    #       住所１/100/全角５０文字（半角全角変換）。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress2" (String) 住所２（番地番号）/100/全角５０文字（半角全角変換）
    #     * "PhoneNumber1" (String) 電話番号昼/15/半角
    #     * "PhoneNumber2" (String) 電話番号夜/15/半角
    #   * "Home2_Information" (Hash)
    #     帰省先情報
    #     * "WholeName" (String) 帰省先名/50/全角２５文字（半角全角変換）
    #     * "Address_ZipCode" (String)
    #       郵便番号/7/半角。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress1" (String)
    #       住所１/100/全角５０文字（半角全角変換）。
    #       郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
    #       郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
    #     * "WholeAddress2" (String) 住所２（番地番号）/100/全角５０文字（半角全角変換）
    #     * "PhoneNumber" (String) 電話番号/15/半角
    #     * "Contraindication1" (String)
    #       禁忌１/100/全角５０文字（半角全角変換）
    #     * "Contraindication2" (String)
    #       禁忌２/100/全角５０文字（半角全角変換）
    #     * "Allergy1" (String)
    #       アレルギー１/100/全角５０文字（半角全角変換）
    #     * "Allergy2" (String)
    #       アレルギー２/100/全角５０文字（半角全角変換）
    #     * "Infection1" (String)
    #       感染症１/100/全角５０文字（半角全角変換）
    #     * "Infection2" (String)
    #       感染症２/100/全角５０文字（半角全角変換）
    #     * "Comment1" (String)
    #       コメント１/100
    #     * "Comment2" (String)
    #       コメント２/100
    #     * "TestPatient_Flag" (String)
    #       テスト患者区分/1
    #     * "Death_Flag" (String)
    #       死亡区分/1
    #     * "Reduction_Reason" (String)
    #       減免事由/2/数値２桁（システム管理の減免事由情報）/未設定は「00 該当なし」とします
    #     * "Discount" (String)
    #       割引率/2/数値２桁（システム管理の割引率情報）/未設定は「00 該当なし」とします
    #     * "Condition1" (String)
    #       状態１/2/数値２桁（システム管理の状態コメント情報１）/未設定は「00 該当なし」とします
    #     * "Condition2" (String)
    #       状態２/2/数値２桁（システム管理の状態コメント情報２）/未設定は「00 該当なし」とします
    #     * "Condition3" (String)
    #       状態３/2/数値２桁（システム管理の状態コメント情報３）/未設定は「00 該当なし」とします
    # @param allow_duplication [Boolean] trueの場合は重複登録警告を無視して登録を行う
    # @param patient_id [String] 作成する患者の患者番号を明示的に指定
    # @return [OrcaApi::PatientService::CreateResult]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v031.pdf
    def create(patient_information, allow_duplication: false, patient_id: "*")
      res = CreateResult.new(call_01(patient_id, patient_information, "New"))
      if !res.ok? && !res.duplicated_patient_candidates.empty? && allow_duplication
        res = CreateResult.new(call_02(patient_information, "New", res))
      end
      res
    end

    # 患者情報の取得
    #
    # @param id [String]
    #   患者ID
    # @return [Result]
    #   日レセからのレスポンス
    # @see https://www.orca.med.or.jp/receipt/tec/api/patientget.html#response
    def get(id)
      Result.new(
        orca_api.call(
          "/api01rv2/patientgetv2",
          http_method: :get,
          params: {
            id: id
          }
        )
      )
    end

    # 患者情報の更新
    # patient_informationは PatientService#create と同じ形式
    #
    # @param id [String] 患者ID
    # @param patient_information [Hash] 更新する患者情報
    # @see PatientService#create
    def update(id, patient_information)
      res = Result.new(call_01(id, nil, "Modify"))
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end

      patient_information = deep_merge_for_request_body(res.patient_information, patient_information)
      res = Result.new(call_02(patient_information, "Modify", res))
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock(locked_result)
    end

    # 患者情報の削除
    #
    # @param id [String] 患者ID
    # @param force [Boolean] trueの場合は強制的に削除する
    def destroy(id, force: false)
      res = Result.new(call_01(id, nil, "Delete"))
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end

      res = Result.new(call_02(res.patient_information, "Delete", res))
      if res.api_result != "S20"
        return res
      end

      res = Result.new(call_02(res.patient_information, "Delete", res))
      if res.ok?
        # 該当患者に受診履歴、病名等の入力がない場合
        locked_result = nil
        return res
      end
      if res.api_result != "S20" || !force
        return res
      end

      # 該当患者に受診履歴、病名等の入力がある場合
      res = Result.new(call_02(res.patient_information, "Delete", res))
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock(locked_result)
    end

    # @!group 患者関連情報

    # @!method get_health_public_insurance
    #   @see PatientService::HealthPublicInsurance#get

    # @!method update_health_public_insurance
    #   @see PatientService::HealthPublicInsurance#update

    # @!method get_health_insurance
    #   @see PatientService::HealthInsurance#get

    # @!method fetch_health_insurance
    #   @see PatientService::HealthInsurance#fetch

    # @!method update_health_insurance
    #   @see PatientService::HealthInsurance#update

    # @!method get_public_insurance
    #   @see PatientService::PublicInsurance#get

    # @!method update_public_insurance
    #   @see PatientService::PublicInsurance#update

    # @!method get_accident_insurance
    #   @see PatientService::AccidentInsurance#get

    # @!method fetch_accident_insurance
    #   @see PatientService::AccidentInsurance#fetch

    # @!method update_accident_insurance
    #   @see PatientService::AccidentInsurance#update

    # @!method get_income
    #   @see PatientService::Income#get

    # @!method update_income
    #   @see PatientService::Income#update

    # @!method get_pension
    #   @see PatientService::Pension#get
    # @!method update_pension
    #   @see PatientService::Pension#update

    # @!method get_maiden
    #   @see PatientService::Maiden#get
    # @!method update_maiden
    #   @see PatientService::Maiden#update

    # @!method get_special_notes
    #   @see PatientService::SpecialNotes#get

    # @!method update_special_notes
    #   @see PatientService::SpecialNotes#update

    # @!method get_personally
    #   @see PatientService::Personally#get
    # @!method update_personally
    #   @see PatientService::Personally#update

    # @!method get_contraindication
    #   @see PatientService::Contraindication#get

    # @!method update_contraindication
    #   @see PatientService::Contraindication#update

    # @!method get_care_insurance
    #   @see PatientService::CareInsurance#get

    # @!method update_care_insurance
    #   @see PatientService::CareInsurance#update

    # @!method get_care_certification
    #   @see PatientService::CareCertification#get

    # @!method update_care_certification
    #   @see PatientService::CareCertification#update

    # @!method get_pi_money
    #   @see PatientService::PiMoney#get

    # @!method fetch_pi_money
    #   @see PatientService::PiMoney#fetch

    # @!method update_pi_money
    #   @see PatientService::PiMoney#update

    # @!method get_pi_etc_money
    #   @see PatientService::PiEtcMoney#get

    # @!method update_pi_etc_money
    #   @see PatientService::PiEtcMoney#update

    # @!endgroup

    %w(
      HealthPublicInsurance
      HealthInsurance
      PublicInsurance
      AccidentInsurance
      Income
      Pension
      Maiden
      SpecialNotes
      Personally
      Contraindication
      CareInsurance
      CareCertification
      PiMoney
      PiEtcMoney
      AllHealthInsurances
      PatientModService
      PatientSearchService
    ).each do |class_name|
      method_suffix = Client.underscore(class_name)
      require_relative "patient_service/#{method_suffix}"
      klass = const_get(class_name)

      method_names = klass.instance_methods & (klass.instance_methods(false) + %i(get update fetch)).uniq
      method_names.each do |method_name|
        define_method("#{method_name}_#{method_suffix}") do |*args|
          klass.new(orca_api).send(method_name, *args)
        end
      end
    end

    private

    def call_01(id, patient_information, patient_mode)
      req = {
        "Request_Number" => "01",
        "Karte_Uid" => orca_api.karte_uid,
        "Patient_ID" => id.to_s,
        "Patient_Mode" => patient_mode,
        "Orca_Uid" => "",
        "Select_Answer" => "",
        "Patient_Information" => patient_information,
      }
      orca_api.call("/orca12/patientmodv31", body: make_body(req))
    end

    def call_02(patient, patient_mode, previous_result)
      res = previous_result
      req = {
        "Request_Number" => res.response_number,
        "Karte_Uid" => orca_api.karte_uid,
        "Patient_ID" => res.patient_information["Patient_ID"],
        "Patient_Mode" => patient_mode,
        "Orca_Uid" => res.orca_uid,
        "Select_Answer" => "Ok",
        "Patient_Information" => patient,
      }
      orca_api.call("/orca12/patientmodv31", body: make_body(req))
    end

    def unlock(locked_result)
      if locked_result&.respond_to?(:orca_uid)
        req = {
          "Request_Number" => "99",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => locked_result.patient_information["Patient_ID"],
          "Orca_Uid" => locked_result.orca_uid,
        }
        orca_api.call("/orca12/patientmodv31", body: make_body(req))
      end
    end

    def deep_merge_for_request_body(dest, src)
      res = dest&.clone || {}
      case src
      when Hash
        src.each do |k, v|
          res[k] = case v
                   when Hash
                     deep_merge_for_request_body(dest[k], v)
                   when nil
                     ""
                   else
                     v
                   end
        end
      end
      res
    end

    def make_body(req)
      { "patientmodv3req1" => req }
    end
  end
end
