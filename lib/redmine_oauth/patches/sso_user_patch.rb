# frozen_string_literal: true

# Redmine plugin OAuth
#
# Gregory Colpart <reg@debian.org>
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

module RedmineOauth
  module Patches
    # Keeps OAuth SSO accounts from retaining local password credentials.
    module SsoUserPatch
      def self.prepended(base)
        base.before_save :clear_oauth_local_credentials
        base.after_save :revoke_oauth_password_tokens
      end

      private

      def clear_oauth_local_credentials
        return unless auth_source.is_a?(AuthSourceOauth)

        self.hashed_password = ''
        self.salt = ''
        self.password = self.password_confirmation = nil
        self.must_change_passwd = false
        self.generate_password = false
      end

      def revoke_oauth_password_tokens
        return unless auth_source.is_a?(AuthSourceOauth)

        Token.where(user_id: id, action: 'recovery').delete_all
        Token.where(user_id: id, action: %w[autologin session]).delete_all if saved_change_to_auth_source_id?
      end
    end
  end
end

Rails.application.config.to_prepare do
  User.prepend RedmineOauth::Patches::SsoUserPatch unless User < RedmineOauth::Patches::SsoUserPatch
end

User.prepend RedmineOauth::Patches::SsoUserPatch unless User < RedmineOauth::Patches::SsoUserPatch
