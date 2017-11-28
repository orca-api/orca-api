if ![3, 4].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  call.rb <path> <params> <body> [http_method]
    params: "" or foo=1 or foo=1,bar=2,baz=3
    body: "" or json or path to json file(ex: example/orca_api/patientlst1req.json)
    http_method: get or post, default is post
  EOS
  exit(1)
end

require_relative "../common"

path = ARGV.shift
params = ARGV.shift
if params.empty?
  params = nil
else
  params = params.split(",").map { |i| i.split("=") }.to_h
end
json = ARGV.shift
if File.exist?(json)
  json = File.read(json)
end
http_method = (ARGV.shift || "post").to_sym

if json.nil? || json.empty?
  body = nil
else
  body = JSON.parse(json)
end

res = @orca_api.call(path, params: params, body: body, http_method: http_method)
puts(res)
