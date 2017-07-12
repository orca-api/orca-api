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
      res = {}
      self.class.attribute_mappings.each do |json_name, attr_name|
        if block_given? && !yield(self, json_name, attr_name)
          next
        end
        value = send(attr_name)
        if !value && omit
          next
        end
        key = make_attributes_key(name_type, json_name, attr_name)
        is_struct = self.class.struct_mappings.key?(attr_name)
        if self.class.array_names.include?(attr_name)
          if value.empty?
            if !omit
              res[key] = []
            end
            next
          end
          found_value = false
          value.reverse.each do |v|
            r = if is_struct
                  v.attributes(name_type: name_type, omit: omit, &include_filter) || {}
                else
                  v || ""
                end
            if omit && r.empty? && !found_value
              next
            end
            res[key] ||= []
            res[key].unshift(r)
            found_value = true
          end
        elsif is_struct
          if !value
            value = self.class.struct_mappings[attr_name].new
          end
          r = value.attributes(name_type: name_type, omit: omit, &include_filter) || {}
          if !r.empty? || !omit
            res[key] = r
          end
        elsif !value || value.empty?
          if !omit
            res[key] = ""
          end
        else
          res[key] = value
        end
      end
      res
    end

    private

    def make_attributes_key(name_type, json_name, attr_name)
      case name_type
      when :symbol
        attr_name.to_sym
      when :json
        json_name
      else
        attr_name
      end
    end
  end
end
