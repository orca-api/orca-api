module OrcaApi #:nodoc:
  module Ext #:nodoc:
    # Shim module for Hash#slice
    module HashSlice
      def self.need_using?
        !::Hash.instance_methods.include?(:slice)
      end

      refine Hash do
        def slice(*keys)
          select { |key, _| keys.include? key }
        end
      end
    end
  end
end
