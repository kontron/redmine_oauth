# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module RedmineOauth
  module Patches
    # AccessToken class patch
    module AccessTokenPatch
      def self.included(base)
        base.instance_eval do
          ##############################################################################################################
          # Overridden methods
          #
          def from_hash(client, hash)
            fresh = hash.dup
            supported_keys = OAuth2::AccessToken::TOKEN_KEY_LOOKUP & fresh.keys
            # plugin's modification do
            # key = supported_keys[0]
            token_type = Setting.plugin_redmine_oauth[:token_type]
            key = token_type.present? && (token_type != 'none') ? token_type : supported_keys[0]
            # end
            extra_tokens_warning(supported_keys, key)
            token = fresh.delete(key)
            new(client, token, fresh)
          end
        end
      end
    end
  end
end

OAuth2::AccessToken.include RedmineOauth::Patches::AccessTokenPatch
