if ![1].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} <json>
    json: path to json file
  EOS
  exit(1)
end

require_relative "./common"

service = @orca_api.new_medical_practice_service

args = JSON.parse(File.read(ARGV.shift))

result = process_medical_warnings(service, :calc_medical_practice_fee, args)
if result.ok?
  $stderr.puts "＊＊＊＊＊正常終了＊＊＊＊＊"
  $stderr.puts "標準出力に出力したJSONを適宜修正してファイルに保存してcrud.rb createの引数に指定してください"

  args["Diagnosis_Information"]["Medical_Information"]["Medical_Info"] = result["Medical_Information"]["Medical_Info"]

  args["Base_Date"] = ""
  args["Ic_Code"] = result.cd_information["Ic_Code"]
  args["Ic_Request_Code"] = result.cd_information["Ic_Request_Code"]
  args["Ic_All_Code"] = ""
  args["Cd_Information"] = {
    "Ad_Money1" => "0",
    "Ad_Money2" => "0",
    "Ic_Money" => result.cd_information["Cd_Information2"]["Ic_Money"],
    "Re_Money" => "",
  }
  args["Print_Information"] = {
    "Print_Prescription_Class" => "0",
    "Print_Invoice_Receipt_Class" => "0",
    "Print_Statement_Class" => "0",
    "Print_Medicine_Information_Class" => "0",
    "Print_Medication_Note_Class" => "0",
    "Print_Appointment_Form_Class" => "0",
  }

  puts JSON.pretty_generate(args)
else
  error(result)
end
