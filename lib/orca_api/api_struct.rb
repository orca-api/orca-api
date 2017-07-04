# coding: utf-8

module OrcaApi
  # 日レセAPIで扱う構造体を表現するクラス
  class ApiStruct
    def self.json_name_to_attr_name(name)
      name
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    def self.define_accessors(mappings)
      json_name_mappings = {}
      struct_mappings = {}
      array_names = []

      mappings.each do |mapping|
        if mapping.is_a?(String)
          mapping = [mapping, {}]
        end
        if !mapping[1][:name]
          mapping[1][:name] = json_name_to_attr_name(mapping[0])
        end
        json_name_mappings[mapping[0]] = mapping[1][:name]
        if mapping[1].key?(:struct)
          struct_mappings[mapping[1][:name]] = mapping[1][:struct]
        end
        if mapping[1][:array]
          array_names << mapping[1][:name]
        end
      end

      define_singleton_method("attribute_mappings") { json_name_mappings.freeze }
      define_singleton_method("struct_mappings") { struct_mappings.freeze }
      define_singleton_method("array_names") { array_names.freeze }

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
        value = (
          if v && self.class.struct_mappings.key?(attr_name)
            if self.class.array_names.include?(attr_name)
              v.map { |attrs|
                self.class.struct_mappings[attr_name].new(attrs)
              }
            else
              self.class.struct_mappings[attr_name].new(v)
            end
          else
            v
          end
        )
        setter_name = "#{attr_name}="
        if respond_to?(setter_name)
          send(setter_name, value)
        end
      end
    end
  end
end
