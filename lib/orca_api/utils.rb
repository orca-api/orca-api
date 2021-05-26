# frozen_string_literal: true

require_relative "ext/hash_transform_values"

module OrcaApi #:nodoc:
  UNDERSCORE_RE1 = /([A-Z]+)([A-Z][a-z])/.freeze
  UNDERSCORE_RE2 = /([a-z\d])([A-Z])/.freeze
  private_constant :UNDERSCORE_RE1, :UNDERSCORE_RE2

  using Ext::HashTransformValues if Ext::HashTransformValues.need_using?

  @_cache = {}

  def self.underscore(str)
    @_cache.fetch(str) do
      @_cache[str] = str.gsub(UNDERSCORE_RE1, '\1_\2').gsub(UNDERSCORE_RE2, '\1_\2').downcase
    end
  end

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
