# -*- coding: utf-8 -*-
require_relative "../common"

disease_service = @orca_api.new_disease_service

params = {
  "Patient_ID" => ARGV.shift, # 患者番号/20/必須
  "Base_Date" => "", # 基準月/10/未設定時はシステム日付を設定
  "Select_Mode" => "", # 転帰済選択区分/3/All or 未指定
}
result = disease_service.get(params)
if result.ok?
  pp result.body
else
  error(result)
end
