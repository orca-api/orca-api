require "abbrev"
require "optparse"
require "time"
require_relative "../common"

actions = %w[create update destroy out_create]
# class=01（登録）->create
# class=02（削除）->destroy
# class=03（変更）->update
# class=04 (外来追加)->out_create

args = {}
json_path = nil
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: ruby #{__FILE__} #{actions.join("|")} [options]
  EOS
  opts.on("--medical-uid MedicalUid * destroy/updateのとき必須", String) { |v| args["Medical_Uid"] = v }
  opts.on("--json JSONファイルのパス", String) { |v| json_path = v }
end

OPS = Abbrev.abbrev(actions)
ops = ARGV.shift.to_s
ops = OPS.find { |(a, e)| ops == a }
unless ops
  STDERR.puts(parser.help)
  exit 1
end
action = ops.last
parser.parse(ARGV)
if json_path.nil? ||
  (action == "destroy" && !args["Medical_Uid"]) ||
  (action == "update" && !args["Medical_Uid"])
  STDERR.puts(parser.help)
  exit 1
end
args = JSON.parse(File.read(json_path)).merge(args)
service = @orca_api.new_interruption_service
result = case action
         when 'create'
           service.create(args)
         when 'destroy'
           service.destroy(args)
         when 'update'
           service.update(args)
         when 'out_create'
           service.out_create(args)
         end
if result.ok?
  print_result(result)
else
  error(result)
end
__END__

# 中途終了データ作成

## 実行例

```
$ ORCA_API_URI=http://xxx bundle exec ruby example/interruption_service/crud.rb create --json ./create.json
```

## create.json

```js
{
  "Patient_ID" : "00501",
  "Diagnosis_Information" : {
    "Department_Code": "01",
    "Physician_Code": "10001",
    "HealthInsurance_Information": {
      "Insurance_Combination_Number": "0001"
    },
    "Medical_Information" : [
      {
        "Medical_Class": "110",
        "Medical_Class_Name": "初診料",
        "Medication_info": [
          {
            "Medication_Code": "111000110",
            "Medication_Name": "初診料",
            "Medication_Number": "1"
          }
        ]
      },
      {
        "Medical_Class": "212",
        "Medical_Class_Name": "内服",
        "Medication_info": [
          {
            "Medication_Code": "621978201",
            "Medication_Name": "サインバルタカプセル２０ｍｇ",
            "Medication_Number": "1"
          },
          {
            "Medication_Code": "099209908",
            "Medication_Name": "一般名記載",
            "Medication_Number": "1"
          }
        ]
      },
      {
        "Medical_Class": "820",
        "Medical_Class_Name": "処方箋料",
        "Medication_info": [
          {
            "Medication_Code": "120003570",
            "Medication_Name": "一般名処方加算２（処方箋料）",
            "Medication_Number": "1"
          }
        ]
      }
    ],
    "Disease_Information": [
      {
        "Disease_InOut": "O",
        "Disease_Single": [
          {
            "Disease_Single_Code": "2500013",
            "Disease_Single_Name": "糖尿病"
          }
        ],
        "Disease_Supplement": {
          "Disease_Sname": "ほげ"
        },
        "Disease_StartDate": "2019-05-01",
        "Disease_Category": "PD"
      }
    ]
  }
}
```

# 中途終了データ削除

## 実行例

```
$ ORCA_API_URI=http://xxx bundle exec ruby example/interruption_service/crud.rb destroy --json ./destroy.json --medical-uid f44b2340-0369-46ee-8c45-da0584e9510c
```

## destroy.json

```js
{
  "Patient_ID" : "00501",
  "Diagnosis_Information" : {
    "Department_Code": "01",
    "Physician_Code": "10001"
  }
}
```

# 中途終了データ変更

## 実行例

```
$ ORCA_API_URI=http://xxx bundle exec ruby example/interruption_service/crud.rb update --json ./update.json --medical-uid f44b2340-0369-46ee-8c45-da0584e9510c
```

## update.json

```js
{
  "Patient_ID" : "00501",
  "Diagnosis_Information" : {
    "Department_Code": "01",
    "Physician_Code": "10001",
    "HealthInsurance_Information": {
      "Insurance_Combination_Number": "0001"
    },
    "Medical_Information" : [
      {
        "Medical_Class": "110",
        "Medical_Class_Name": "初診料",
        "Medication_info": [
          {
            "Medication_Code": "111000110",
            "Medication_Name": "初診料",
            "Medication_Number": "1"
          }
        ]
      }
    ]
  }
}

```

# 中途終了データ外来追加

## 実行例

```
# 患者番号、診療日付、診療科、保険組合せが一致する中途データが存在する状態で実行
$ ORCA_API_URI=http://xxx bundle exec ruby example/interruption_service/crud.rb out_create --json ./out_create.json
```

## out_create.json

```
{
  "Perform_Date": "2019-05-01",
  "Patient_ID": "00501",
  "Diagnosis_Information": {
    "Department_Code": "01",
    "Physician_Code": "10001",
    "HealthInsurance_Information": {
      "Insurance_Combination_Number": "0001"
    },
    "Medical_Information" : [
      {
        "Medical_Class": "600",
        "Medication_info": [
          {
            "Medication_Code": "160118810",
            "Medication_Number": "1"
          }
        ]
      }
    ]
  }
}
```

