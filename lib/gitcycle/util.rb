module Gitcycle
  class Util
    class <<self

      def deep_merge(hash, other_hash)
        other_hash.each_pair do |k,v|
          tv = hash[k]
          hash[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? deep_merge(tv, v) : v
        end
        hash
      end
      
      def symbolize_keys(value)
        if value.is_a?(Array)
          value.collect { |v| symbolize_keys(v) }

        elsif value.is_a?(Hash)
          value.inject({}) do |memo, (k, v)|
            k = (k.to_sym rescue k) || k
            v = symbolize_keys(v)
            
            memo[k] = v
            memo
          end

        else value
        end
      end
    end
  end
end