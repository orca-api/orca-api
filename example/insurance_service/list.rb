require "optparse"
require_relative "../common"

args = {}
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
Usage: #{opts.program_name} [options]
  EOS
  opts.on("--base-date YYYY-mm-dd形式", String) { |v| args["Base_Date"] = v }
end

parser.parse!(ARGV)

service = @orca_api.new_insurance_service
result = service.list(args["Base_Date"])
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
