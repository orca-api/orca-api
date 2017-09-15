# -*- coding: utf-8 -*-
require_relative "../common"

patient_service = @orca_api.new_patient_service

attrs = {
  "WholeName" => "テスト　カンジャ", # 漢字氏名/50/必須/全角２５文字
  "WholeName_inKana" => "テスト　カンジャ", # カナ氏名/50/必須/全角２５文字（半角全角変換）
  "BirthDate" => "1965-04-04", # 生年月日/10/必須
  "Sex" => "1", # Sex/性別/1/1：男、2：女
  "HouseHolder_WholeName" => "", # 世帯主名称/50/全角２５文字
  "Relationship" => "", # 続柄/30/全角１５文字（半角全角変換）
  "Occupation" => "", # 職業/20/全角１５文字（半角全角変換）
  "NickName" => "", # 通称名称/50/全角２５文字
  "CellularNumber" => "", # 携帯電話番号/15/半角
  "FaxNumber" => "", # 15/半角
  "EmailAddress" => "", # メールアドレス/50
  "Home_Address_Information" => { # 自宅情報
    "Address_ZipCode" => "", # 郵便番号/7/半角　　※２
    "WholeAddress1" => "", # 住所１/100/全角５０文字（半角全角変換）　※２
    "WholeAddress2" => "", # 住所２（番地番号）/100/全角５０文字（半角全角変換）
    "PhoneNumber1" => "", # 自宅電話番号/15/半角
    "PhoneNumber2" => "", # 連絡先電話番号/15/半角
  },
  "WorkPlace_Information" => { # 勤務先情報
    "WholeName" => "", # 勤務先名称/50
    "Address_ZipCode" => "", # 郵便番号/7/半角　　※２
    "WholeAddress1" => "", # 住所１/100/全角５０文字（半角全角変換）　※２
    "WholeAddress2" => "", # 住所２（番地番号）/100/全角５０文字（半角全角変換）
    "PhoneNumber" => "", # 勤務先電話番号/15/半角
  },
  "Contact_Information" => { # 連絡先情報
    "WholeName" => "", # 連絡先名/50/全角２５文字（半角全角変換）
    "Relationship" => "", # 連絡先続柄/30/全角１５文字（半角全角変換）
    "Address_ZipCode" => "", # 郵便番号/7/半角　　※２
    "WholeAddress1" => "", # 住所１/100/全角５０文字（半角全角変換）　※２
    "WholeAddress2" => "", # 住所２（番地番号）/100/全角５０文字（半角全角変換）
    "PhoneNumber1" => "", # 電話番号昼/15/半角
    "PhoneNumber2" => "", # 電話番号夜/15/半角
  },
  "Home2_Information" => { # 帰省先情報
    "WholeName" => "", # 帰省先名/50/全角２５文字（半角全角変換）
    "Address_ZipCode" => "", # 郵便番号/7/半角　　※２
    "WholeAddress1" => "", # 住所１/100/全角５０文字（半角全角変換）　※２
    "WholeAddress2" => "", # 住所２（番地番号）/100/全角５０文字（半角全角変換）
    "PhoneNumber" => "", # 電話番号/15/半角
  },
  "Contraindication1" => "", # 禁忌１/100/全角５０文字（半角全角変換）
  "Contraindication2" => "", # 禁忌２/100/全角５０文字（半角全角変換）
  "Allergy1" => "", # アレルギー１/100/全角５０文字（半角全角変換）
  "Allergy2" => "", # アレルギー２/100/全角５０文字（半角全角変換）
  "Infection1" => "", # 感染症１/100/全角５０文字（半角全角変換）
  "Infection2" => "", # 感染症２/100/全角５０文字（半角全角変換）
  "Comment1" => "", # コメント１/100
  "Comment2" => "", # コメント２/100
  "TestPatient_Flag" => "", # テスト患者区分/1
  "Death_Flag" => "", # 死亡区分/1
  "Reduction_Reason" => "", # 減免事由/2/数値２桁（システム管理の減免事由情報）　※４
  "Discount" => "", # 割引率/2/数値２桁（システム管理の割引率情報）　　※４
  "Condition1" => "", # 状態１/2/数値２桁（システム管理の状態コメント情報１）※４
  "Condition2" => "", # 状態２/2/数値２桁（システム管理の状態コメント情報２）※４
  "Condition3" => "", # 状態３/2/数値２桁（システム管理の状態コメント情報３）※４
}
# ※２　郵便番号があり住所１に設定がなければ郵便番号から住所を編集します。　
#　　　郵便番号に設定がない場合は住所１から郵便番号を編集します。（システム管理の設定による）　　
# ※４　未設定は「00 該当なし」とします
# ※全角項目で（半角全角変換）を記載している項目は半角文字を全角文字へ変換します。拡張文字は■に変換します。

result = patient_service.create(attrs, allow_duplication: ARGV.shift == "t")
if result.ok?
  pp result.patient_information #=> 登録結果
else
  error(result)
  if !result.duplicated_patient_candidates.empty?
    # 二重登録疑いの患者が存在する
    puts
    puts "＊＊＊＊＊二重登録疑いの患者一覧＊＊＊＊＊"
    pp result.duplicated_patient_candidates #=> 二重登録疑いの患者の一覧
    puts
    puts "問題なければ、コマンドの引数に「t」を付与して強制登録してください。"
  end
end
