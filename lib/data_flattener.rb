# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine OAuth plugin.
#
# Redmine OAuth plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine OAuth plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine OAuth plugin. If not, see
# <https://www.gnu.org/licenses/>.

# Provides utility methods to transform nested hashes into flat structures.
module DataFlattener
  # Shared logic to avoid code repetition between Hash and Array refinements.
  module SharedMethods
    # Flattens nested Ruby data (Hash/Array) into a single-level Hash.
    # Nested keys are joined by a specified separator string (default ".").
    #
    # @note This method is available only when 'using DataFlattener' is active.
    #
    # @example Basic usage
    #   using DataFlattener
    #   data = { user: { name: "Alice", tags: ["dev", "ruby"] } }
    #   data.flatten_data(separator: "_")
    #   # => { "user_name" => "Alice", "user_tags_0" => "dev", "user_tags_1" => "ruby" }
    #
    # @param separator [String] The character used to join keys (keyword).
    # @param parent_key [Array] Internal use for tracking the key path (keyword).
    # @param result [Hash] Internal use for accumulating the flattened keys (keyword).
    #
    # @raise [ArgumentError] If the separator is not a String.
    # @return [Hash] A single-level Hash of joined key-paths to values.
    def flatten_data(separator: '.', parent_key: [], result: {})
      DataFlattener.flatten_recursive(self, separator: separator, parent_key: parent_key, result: result)
    end
  end

  # The recursive engine. We use a class method to ensure recursion works
  # inside the refinement scope without a NoMethodError.
  def self.flatten_recursive(data, separator:, parent_key:, result:)
    raise ArgumentError, 'separator must be a String' unless separator.is_a?(String)

    data ||= {}
    data.each_with_index.each do |(k, v), i|
      # if data is a Hash key=k, value=v
      # if data is an Array index=i, value=k
      key, value = data.is_a?(Hash) ? [k, v] : [i, k]
      new_key = [*parent_key, key]

      # decide to continue recursing or save the value un result
      if value.is_a?(Hash) || value.is_a?(Array)
        flatten_recursive(value, separator: separator, parent_key: new_key, result: result)
      else
        result[new_key.join(separator)] = value
      end
    end
    result
  end

  # Refine the core classes. Use import_methods
  refine Hash do
    import_methods SharedMethods
  end

  refine Array do
    import_methods SharedMethods
  end
end
