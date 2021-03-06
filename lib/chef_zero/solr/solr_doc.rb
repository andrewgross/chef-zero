module ChefZero
  module Solr
    # This does what expander does, flattening the json doc into keys and values
    # so that solr can search them.
    class SolrDoc
      def initialize(json, id)
        @json = json
        @id = id
      end

      def [](key)
        values = matching_values { |match_key| match_key == key }
        values[0]
      end

      def matching_values(&block)
        result = {}
        key_values(nil, @json) do |key, value|
          if block.call(key)
            if result.has_key?(key)
              result[key] << value.to_s
            else
              result[key] = value.to_s.clone
            end
          end
        end
        # Handle manufactured value(s)
        if block.call('X_CHEF_id_CHEF_X')
          if result.has_key?('X_CHEF_id_CHEF_X')
            result['X_CHEF_id_CHEF_X'] << @id.to_s
          else
            result['X_CHEF_id_CHEF_X'] = @id.to_s.clone
          end
        end

        result.values
      end

      private

      def key_values(key_so_far, value, &block)
        if value.is_a?(Hash)
          value.each_pair do |child_key, child_value|
            block.call(child_key, child_value.to_s)
            if key_so_far
              new_key = "#{key_so_far}_#{child_key}"
              key_values(new_key, child_value, &block)
            else
              key_values(child_key, child_value, &block) if child_value.is_a?(Hash) || child_value.is_a?(Array)
            end
          end
        elsif value.is_a?(Array)
          value.each do |child_value|
            key_values(key_so_far, child_value, &block)
          end
        else
          block.call(key_so_far || 'text', value.to_s)
        end
      end
    end
  end
end
