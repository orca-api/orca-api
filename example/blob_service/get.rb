if ![1, 2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  get.rb <uid> [output_dir]
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_blob_service

uid = ARGV.shift
output_dir = ARGV.shift || "."

result = service.get(uid)
if result.ok?
  File.open(File.join(output_dir, uid), "wb") do |f|
    buf = ""
    data = result.raw
    while data.read(1024, buf)
      f.write(buf)
    end
  end
else
  error(result)
end
