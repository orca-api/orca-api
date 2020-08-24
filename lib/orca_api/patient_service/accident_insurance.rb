# frozen_string_literal: true

module OrcaApi
  class PatientService < Service
    # 患者労災・自賠責保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v033.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v033_err.pdf
    class AccidentInsurance < Service
      # 選択項目が未指定であることを表現するクラス
      class UnselectedError < Result
        def ok?
          false
        end

        def message
          '選択項目が未指定です。'
        end
      end

      # 取得
      def get(id)
        res = call_01(id)
        if !res.locked?
          unlock(res)
        end
        res
      end

      # 取得(ロックなし)
      #
      # @see https://www.orcamo.co.jp/api-council/members/standards/?haori_patientmod_search
      def fetch(id)
        call_00(id)
      end

      # 登録・更新・削除
      def update(id, params)
        res = call_01(id)
        if !res.locked?
          locked_result = res
        end
        if !res.ok?
          return res
        end

        res = call_02(params, res)
        if !res.ok?
          return res
        end

        res = call_03_with_answer(params, res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock(locked_result)
      end

      private

      def call_00(id)
        req = {
          "Request_Number" => "00",
          "Patient_Information" => {
            "Patient_ID" => id.to_s,
          }
        }
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      def call_01(id)
        req = {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => "",
          "Patient_Information" => {
            "Patient_ID" => id.to_s,
          }
        }
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      def call_02(params, previous_result)
        res = previous_result
        req = params.merge(
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information
        )
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      def call_03(previous_result, answer = nil)
        res = previous_result
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "Accident_Insurance_Information" => res["Accident_Insurance_Information"],
        }
        if answer
          req["Select_Answer"] = answer["Select_Answer"]
        end
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      # see. lib/orca_api/patient_service/health_public_insurance_common.rb
      def call_03_with_answer(params, previous_result)
        res = call_03(previous_result)
        return res if res.ok?

        while !res.ok?
          if res.api_result == "S20"
            ps = res.patient_select_information["Patient_Select"]
            psm = res.patient_select_information["Patient_Select_Message"]
            psi = Array(params["Patient_Select_Information"]).find do |e|
              ps == e["Patient_Select"] && psm == e["Patient_Select_Message"]
            end
            if psi
              res = call_03(res, psi)
            else
              return UnselectedError.new(res.raw)
            end
          else
            break
          end
        end
        res
      end

      def unlock(locked_result)
        if locked_result&.respond_to?(:orca_uid)
          req = {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => locked_result.orca_uid,
            "Patient_Information" => locked_result.patient_information,
          }
          orca_api.call("/orca12/patientmodv33", body: make_body(req))
        end
      end

      def make_body(req)
        { "patientmodv3req3" => req }
      end
    end
  end
end
