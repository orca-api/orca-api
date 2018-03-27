require "optparse"
require_relative "../common"

base_date = ""
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: #{opts.program_name} [options]
  EOS
  opts.on("--base-date 基準日 YYYY-mm-dd", String) { |v| base_date = v }
end
parser.parse(ARGV)

service = @orca_api.new_find_service

result = service.settings(base_date)
if result.ok?
  print_result(result)
else
  error(result)
end
