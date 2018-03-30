require "optparse"
require_relative "../common"

args = {}
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: #{opts.program_name} <json>
         json: JSONファイルのパス
  EOS
  opts.on("--selection 検索結果返却開始・終了件数。<開始>..<終了>形式", String) do |v|
    first, last = *v.strip.split("..")
    if !last
      last = first
    end
    args["Selection"] = {
      "First" => first,
      "Last" => last,
    }
  end
end
json_path = ARGV.shift
parser.parse(ARGV)

service = @orca_api.new_find_service

result = service.find(JSON.parse(File.read(json_path)))
args["Orca_Uid"] = result["Orca_Uid"]
begin
  if !result.ok?
    error(result)
    exit(1)
  end
  puts "検索指示の結果"
  print_result(result)

  while (result = service.result(args)).doing?
    sleep(1)
  end

  if result.ok?
    puts "検索結果返却の結果"
    print_result(result)
  else
    error(result)
  end
ensure
  result = service.finish(args)
  if result.ok?
    puts "照会終了の結果"
    print_result(result)
  else
    error(result)
  end
end
