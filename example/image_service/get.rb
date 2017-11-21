if ![1, 2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  get.rb <image_id> [output_dir]
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_image_service

image_id = ARGV.shift
output_dir = ARGV.shift || "."

result = service.get(image_id)
if result.ok?
  require "zip"

  Zip::File.open_buffer(result.raw) do |zf|
    zf.extract(zf.first, File.join(output_dir, zf.first.name))
  end
else
  error(result)
end
