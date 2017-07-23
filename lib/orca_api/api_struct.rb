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
      update(attributes)
    end

    def update(attributes)
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
      self
    end

    def attributes(name_type: nil, omit: true, &include_filter)
      args = { name_type: name_type, omit: omit }
      res = {}
      self.class.attribute_mappings.each do |json_name, attr_name|
        if block_given? && !yield(self, json_name, attr_name)
          next
        end
        value = send(attr_name)
        if omit && (!value || (!value.is_a?(ApiStruct) && value.empty?))
          next
        end
        if (v = attributes_convert(value, attr_name, args, &include_filter))
          res[attributes_make_key(name_type, json_name, attr_name)] = v
        end
      end
      res
    end

    private

    def attributes_make_key(name_type, json_name, attr_name)
      case name_type
      when :symbol
        attr_name.to_sym
      when :json
        json_name
      else
        attr_name
      end
    end

    def attributes_convert(value, attr_name, args, &include_filter)
      struct_class = self.class.struct_mappings[attr_name]
      if self.class.array_names.include?(attr_name)
        attributes_convert_array(value, struct_class, args, &include_filter)
      elsif struct_class
        attributes_convert_struct(value, struct_class, args, &include_filter)
      else
        value ? value : ""
      end
    end

    def attributes_convert_array(value, struct_class, args, &include_filter)
      if !value || value.empty?
        return []
      end

      res = if struct_class
              value.map { |v|
                v.attributes(args, &include_filter)
              }
            else
              value.map { |v|
                v || ""
              }
            end

      if args[:omit]
        res.length.times do
          if res.last.empty?
            res.pop
          else
            break
          end
        end
        if res.empty?
          res = nil
        end
      end

      res
    end

    def attributes_convert_struct(value, struct_class, args, &include_filter)
      if !value
        value = struct_class.new
      end
      v = value.attributes(args, &include_filter)
      if args[:omit] && v.empty?
        v = nil
      end
      v
    end
  end
end
