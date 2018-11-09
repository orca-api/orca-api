# frozen_string_literal: true

module OrcaApi #:nodoc:
  UNDERSCORE_RE1 = /([A-Z]+)([A-Z][a-z])/.freeze
  UNDERSCORE_RE2 = /([a-z\d])([A-Z])/.freeze
  private_constant :UNDERSCORE_RE1, :UNDERSCORE_RE2

  @_cache = {}

  def self.underscore(str)
    @_cache.fetch(str) do
      @_cache[str] = str.gsub(UNDERSCORE_RE1, '\1_\2').gsub(UNDERSCORE_RE2, '\1_\2').downcase
    end
  end

  # Shim module for Hash#transform_values
  module HashTransformValues
    refine Hash do
      def transform_values
        return to_enum :transform_values unless block_given?

        map do |k, v|
          r = yield v
          [k, r]
        end.to_h
      end
    end
  end
  using HashTransformValues unless Hash.instance_methods.include? :transform_values

  def self.trim_response(hash)
    hash.transform_values do |v|
      case v
      when Hash
        trim_response(v)
      when Array
        v.reverse_each.drop_while(&:empty?).reverse.map { |e| trim_response(e) }
      else
        v
      end
    end
  end
end
