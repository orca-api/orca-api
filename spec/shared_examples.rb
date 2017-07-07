# -*- coding: utf-8 -*-

RSpec.shared_examples "ApiStructを日レセAPIのレスポンスやハッシュで初期化できること" do |target_class, response_json|
  # ApiStruct(api_struct_class)の各属性がattributesと等しいことを確認するためのexampleを定義する
  def self.expect_to_api_struct(api_struct_class, attributes)
    let(:attributes) { attributes }

    it { is_expected.to be_instance_of(api_struct_class) }

    normal_attributes = {}
    api_struct_class.attribute_mappings.each do |json_name, attr_name|
      converted_json_name = convert_json_name_to_attr_name(json_name)

      if api_struct_class.struct_mappings.key?(attr_name)
        inner_class = api_struct_class.struct_mappings[attr_name]

        describe attr_name do
          subject { super().send(attr_name) }

          if api_struct_class.array_names.include?(attr_name)
            if (v = attributes[converted_json_name])
              empty_indices = []
              v.each.with_index do |inner_attributes, index|
                if inner_attributes.empty?
                  empty_indices.push(index)
                else
                  describe "[#{index}]" do
                    subject { super()[index] }

                    expect_to_api_struct(inner_class, inner_attributes)
                  end
                end
              end
              if !empty_indices.empty?
                describe "[" + empty_indices.join("][") + "]" do
                  it "属性の値はすべてnilであること" do
                    empty_indices.each do |index|
                      inner_class.attribute_mappings do |inner_attr_name|
                        expect(subject[index][inner_attr_name]).to be_nil
                      end
                    end
                  end
                end
              end
            else
              it { is_expected.to be_nil }
            end
          elsif (v = attributes[converted_json_name])
            expect_to_api_struct(inner_class, v)
          else
            it { is_expected.to be_nil }
          end
        end
      else
        normal_attributes[attr_name] = attributes[converted_json_name]
      end
    end

    it normal_attributes.keys.join(", ") + "が正しいこと" do
      normal_attributes.each do |attr_name, value|
        expect(subject.send(attr_name)).to eq(value)
      end
    end
  end

  # JSONの属性名をApiStructの属性名に変換する
  def self.json_name_to_attr_name(name)
    name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
  end

  # 日レセのレスポンスのキーをconvert_json_name_to_attr_nameで変換したキーに置き換えたハッシュを生成する
  def self.make_attributes_from_response_json(json)
    result = {}
    json.each do |json_name, value|
      attr_name = convert_json_name_to_attr_name(json_name)
      case value
      when Hash
        result[attr_name] = make_attributes_from_response_json(value)
      when Array
        result[attr_name] ||= []
        value.each.with_index do |v, index|
          result[attr_name][index] = make_attributes_from_response_json(v)
        end
      else
        result[attr_name] = value
      end
    end
    result
  end

  shared_examples "対象のApiStructを生成して各属性が正しいことを確認するためのexampleを定義する" do |attributes|
    subject { target_class.new(attributes) }

    expect_to_api_struct(target_class, attributes)
  end

  describe "日レセAPIのレスポンスから生成する" do
    def self.convert_json_name_to_attr_name(json_name)
      json_name
    end

    include_examples "対象のApiStructを生成して各属性が正しいことを確認するためのexampleを定義する", response_json
  end

  describe "属性名を文字列で指定した属性値から生成する" do
    def self.convert_json_name_to_attr_name(json_name)
      json_name_to_attr_name(json_name)
    end

    include_examples "対象のApiStructを生成して各属性が正しいことを確認するためのexampleを定義する", make_attributes_from_response_json(response_json)
  end

  describe "属性名を文字列で指定した属性値から生成する" do
    def self.convert_json_name_to_attr_name(json_name)
      json_name_to_attr_name(json_name).to_sym
    end

    include_examples "対象のApiStructを生成して各属性が正しいことを確認するためのexampleを定義する", make_attributes_from_response_json(response_json)
  end
end
