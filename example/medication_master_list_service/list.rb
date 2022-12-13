require "abbrev"
require "optparse"
require "time"
require_relative "../common"

args = {}
json_path = nil

parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
    Usage: ruby #{__FILE__} [options]
  EOS

  opts.on("--request-number リクエスト番号", String) { |v| args["Request_NUmber"] = v }
  opts.on("--karte-uid 電子カルテＵＩＤ", String) { |v| args["Karte_Uid"] = v }
  opts.on("--orca-uid オルカＵＩＤ ", String) { |v| args["Orca_Uid"] = v }
  opts.on("--base-date 基準日 YYYY-mm-dd形式", String) { |v| args["Base_Date"] = v }
  opts.on("--effective-mode 有効モード", String) { |v| args["Effective_Mode"] = v }
  opts.on("--data-format データフォーマット", String) { |v| args["Data_Format"] = v }
end

parser.parse(ARGV)
service = @orca_api.new_medication_master_list_service
result = service.list(args)

if result.ok?
  print_result(result)
else
  error(result)
end
__END__