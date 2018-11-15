require_relative "service"

module OrcaApi
  # 患者収納情報を扱うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667
  # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api023.pdf
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_shunou.data/api023_err.pdf
  class IncomeService < Service
    PATH = "/orca23/incomev3".freeze
    REQUEST_NAME = "incomev3req".freeze

    # 請求一覧
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api1
    def list(args)
      res = call_01("01", args)
      unlock(res)
      res
    end

    # 請求確認
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api2
    def get(args)
      res = call_01("02", args)
      unlock(res)
      res
    end

    # 入金
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api3
    def update(args)
      common_update_process(args, "01")
    end

    # 履歴修正
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api4
    def update_history(args)
      common_update_process(args, "02")
    end

    # 入金取消
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api5
    def cancel(args)
      common_update_process(args, "03")
    end

    # 返金
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api6
    def pay_back(args)
      common_update_process(args, "04")
    end

    # 再計算
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api7
    def recalculate(args)
      common_update_process(args, "05")
    end

    # 一括再計算
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api8
    def bulk_recalculate(args)
      common_update_process(args, "06")
    end

    # 一括入返金
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api9
    def bulk_update(args)
      common_update_process(args, "07")
    end

    # 請求取消
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api10
    def destroy(args)
      common_update_process(args, "08")
    end

    # 再発行
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19667#api11
    def reprint(args)
      common_update_process(args, "09")
    end

    private

    def common_update_process(args, mode)
      res = locked_result = lock(args)
      if !res.ok?
        return res
      end

      call_02(mode, args, res)
    ensure
      unlock(locked_result)
    end

    def lock(args)
      if args.key?("InOut") && args.key?("Invoice_Number")
        mode = "02"
      else
        mode = "01"
        args = args.merge(
          "Information_Class" => "1",
          "Start_Month" => "0000-01",
          "Selection" => {
            "First" => "1",
            "Last" => "1",
          }
        )
      end
      call_01(mode, args)
    end

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
        "Patient_ID" => res["Patient_ID"]
      )
      if (income_detail = res["Income_Detail"])
        req["InOut"] = income_detail["InOut"]
        req["Invoice_Number"] = income_detail["Invoice_Number"]
      end
      Result.new(orca_api.call(PATH, body: { REQUEST_NAME => req }))
    end

    def unlock(locked_result)
      if locked_result&.respond_to?(:orca_uid)
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
