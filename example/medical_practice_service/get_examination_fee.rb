if ![1].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} <json>
    json: path to json file
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_medical_practice_service

args = JSON.parse(File.read(ARGV.shift))
diagnosis_information = args["Diagnosis_Information"]
medical_information = diagnosis_information["Medical_Information"]
if (medical_info = medical_information["Medical_Info"])
  medical_info_0 = medical_info.first
  medical_information["Medical_Class"] = medical_info_0["Medical_Class"]
  medical_information["Medical_Class_Name"] = medical_info_0["Medical_Class_Name"]
  medical_information["Medication_Info"] = medical_info_0["Medication_Info"].first
end

result = service.get_examination_fee(args)
if result.ok?
  $stderr.puts "＊＊＊＊＊正常終了＊＊＊＊＊"
  $stderr.puts "標準出力に出力したJSONを適宜修正してファイルに保存してcalc_medical_practice_fee.rbの引数に指定してください"

  %w(
    Department_Code
    Department_Name
    Physician_Code
    Physician_WholeName
  ).each do |name|
    diagnosis_information[name] = result[name]
  end
  diagnosis_information["Outside_Class"] = ""
  args["Medical_Select_Information"] = [
    {
      "Medical_Select" => "",
      "Select_Answer" => "",
    }
  ]
  args["Delete_Number_Info"] = [
    {
      "Delete_Number" => "",
    }
  ]

  puts JSON.pretty_generate(args)
else
  error(result)
end
