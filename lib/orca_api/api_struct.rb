# coding: utf-8

module OrcaApi
  # 日レセAPIで扱う構造体を表現するクラス
  class ApiStruct
    def self.define_accessors(json_name_mappings, struct_mappings = {})
      define_singleton_method("attribute_mappings") { json_name_mappings.freeze }
      define_singleton_method("struct_mappings") { struct_mappings.freeze }

      json_name_mappings.each do |json_name, attr_name|
        attr_accessor attr_name
        alias_method(json_name, attr_name)
        alias_method("#{json_name}=", "#{attr_name}=")
      end
    end

    def initialize(attributes = {})
      attributes.each do |k, v|
        k = k.to_s
        attr_name = self.class.attribute_mappings[k] || k
        if self.class.struct_mappings.key?(attr_name) && v.is_a?(Hash)
          v = self.class.struct_mappings[attr_name].new(v)
        end
        setter_name = "#{attr_name}="
        if respond_to?(setter_name)
          send(setter_name, v)
        end
      end
    end
  end
end
