# coding: utf-8

require_relative "service"

module OrcaApi
  # 患者収納情報を扱うサービスを表現したクラス
  #
  # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api023.pdf
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_shunou.data/api023_err.pdf
  class IncomeService < Service
    PATH = "/orca23/incomev3".freeze
    REQUEST_NAME = "incomev3req".freeze

    # 請求一覧
    def list(args)
      res = call_01("01", args)
      if !res.locked?
        unlock(res)
      end
      res
    end

    # 請求確認
    def get(args)
      res = call_01("02", args)
      if !res.locked?
        unlock(res)
      end
      res
    end

    # 入金
    def update(args)
      res = call_01("02", args)
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end
      call_02("01", args, res)
    ensure
      unlock(locked_result)
    end

    private

    def call_01(mode, args)
      req = args.merge(
        "Request_Number" => "01",
        "Request_Mode" => mode,
        "Karte_Uid" => orca_api.karte_uid
      )
      Result.new(orca_api.call(PATH, body: { REQUEST_NAME => req }))
    end

    def call_02(mode, args, previous_result)
      res = previous_result
      req = args.merge(
        "Request_Number" => "02",
        "Request_Mode" => mode,
        "Karte_Uid" => orca_api.karte_uid,
        "Orca_Uid" => res.orca_uid,
        "Patient_ID" => res["Patient_ID"],
        "InOut" => res["Income_Detail"]["InOut"],
        "Invoice_Number" => res["Income_Detail"]["Invoice_Number"]
      )
      Result.new(orca_api.call(PATH, body: { REQUEST_NAME => req }))
    end

    def unlock(locked_result)
      if locked_result # && locked_result.respond_to?(:orca_uid)
        req = {
          "Request_Number" => "99",
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => locked_result.orca_uid,
        }
        orca_api.call(PATH, body: { REQUEST_NAME => req })
      end
    end
  end
end
