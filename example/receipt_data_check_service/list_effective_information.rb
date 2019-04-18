if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} perform_month submission_mode
    perform_month: YYYY-mm
    submission_mode: 医保の場合 02:社保 03:国保 04:広域。労災の場合 05。
  EOS
  exit(1)
end

require_relative "../common"

perform_month = ARGV.shift
submission_mode = ARGV.shift

service = @orca_api.new_receipt_data_check_service
result = service.list_effective_information(
  Perform_Month: perform_month,
  Submission_Mode: submission_mode
)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
__END__

# 必要に応じてORCA_API_URIを設定した上で下記のように実行する

$ bundle exec ruby example/receipt_data_check_service/list_effective_information.rb 2019-02 02
