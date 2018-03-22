require "optparse"
require_relative "../common"

args = {
  "Diagnosis_Information" => {
    "Medical_Information" => {},
  },
}

parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
Usage: #{opts.program_name} <patient_id> <department_code> [options]
        patient_id: 患者番号
        department_code: 診療科

  EOS
  opts.on("--perform-date 診療日付 YYYY-mm-dd形式。未指定ならばシステム日付", String) { |v| args["Perform_Date"] = v }
  opts.on("--doctors-fee 診察料区分 01:初診、02:再診、03:電話再診、09:診察料なし。未指定ならば病名などから診察料を返却する",
          String) { |v| args["Diagnosis_Information"]["Medical_Information"]["Doctors_Fee"] = v }
  opts.on("--physician-Code ドクターコード", String) { |v| args["Diagnosis_Information"]["Physician_Code"] = v }
end

parser.parse!(ARGV)
if !(args["Patient_ID"] = ARGV.shift) ||
    !args["Diagnosis_Information"]["Department_Code"] = ARGV.shift
  puts(parser)
  exit(1)
end

service = @orca_api.new_medical_practice_service

result = service.get_default(args)
if result.ok?
  $stderr.puts "＊＊＊＊＊正常終了＊＊＊＊＊"
  $stderr.puts "標準出力に出力したJSONを適宜修正してファイルに保存してget_examination_fee.rbの引数に指定してください"

  result["Medical_Information"].each.with_index(1) do |medical_information, i|
    if result["Medical_Information"].length > 1
      puts "/* no.#{i} */"
    end

    hash = {
      "Patient_ID" => result["Patient_Information"]["Patient_ID"],
      "Perform_Date" => result["Perform_Date"],
      "Diagnosis_Information" => {
        "Department_Code" => result["Department_Code"],
        "Department_Name" => result["Department_Name"],
        "Physician_Code" => args["Diagnosis_Information"]["Physician_Code"] || "TODO",
        "Physician_WholeName" => "",
        "HealthInsurance_Information" => result["Patient_Information"]["HealthInsurance_Information"],
        "Medical_Information" => {
          "OffTime" => "",
          "Doctors_Fee" => args["Diagnosis_Information"]["Medical_Information"]["Doctors_Fee"] || "",
          "Medical_Info" => medical_information["Medical_Info"],
        },
      },
    }
    puts JSON.pretty_generate(hash)

    if result["Medical_Information"].length > 1
      puts
    end
  end
else
  error(result)
end
