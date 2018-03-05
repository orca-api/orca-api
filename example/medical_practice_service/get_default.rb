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
  print_result(result)
else
  error(result)
end
