module OrcaApi #:nodoc:
  module Ext #:nodoc:
    # Shim module for Hash#transform_values
    module HashTransformValues
      def self.need_using?
        !::Hash.instance_methods.include?(:transform_values)
      end

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
  end
end
