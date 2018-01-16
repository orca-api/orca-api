require "abbrev"
require "optparse"
require_relative "../common"

params = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{opts.program_name} create|read|update|delete [options]"
  opts.on("-u user_id", String) { |v| params[:user] = v }
  opts.on("-p password", String) { |v| params[:pass] = v }
  opts.on("-n name", String) { |v| params[:name] = v }
  opts.on("-k kana_name", String) { |v| params[:kana] = v }
end

OPS = Abbrev.abbrev(%w[create read update delete])
ops = ARGV.shift.to_s
ops = OPS.find { |(a, e)| ops == a }
unless ops
  STDERR.puts parser.help
  exit 1
end
parser.parse ARGV

service = @orca_api.new_physician_service
result = case ops.last
         when "read"
           raise NotImplementedError
         when "create"
           service.create("User_Id" => params[:user],
                          "User_Password" => params[:pass],
                          "Full_Name" => params[:name],
                          "Kana_Name" => params[:kana])
         when "update"
           service.update(params[:user],
                          "New_User_Password" => params[:pass],
                          "New_Full_Name" => params[:name],
                          "New_Kana_Name" => params[:kana])
         when "delete"
           service.destroy(params[:user])
         end
pp result.body
