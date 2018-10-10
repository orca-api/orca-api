require_relative "../common"

def process_medical_warnings(service, method_name, args)
  while !((result = service.send(method_name, args)).ok?)
    if !result.warning? || result.medical_warnings.empty?
      return result
    end
    result.medical_warnings.each do |i|
      puts("＊＊＊＊＊警告＊＊＊＊＊")
      puts(i.values.join("\n"))
      print("警告を無視して処理を進めますか? (Y/n)")
      if /\An/ =~ (gets || "").strip.downcase
        return result
      end
      args["Ignore_Medical_Warnings"] ||= []
      args["Ignore_Medical_Warnings"] << { "Medical_Warning" => i["Medical_Warning"] }
    end
  end
  result
end
