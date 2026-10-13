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

# OAuth users are authenticated by RedmineOauthController, not by this password backend.
class AuthSourceOauth < AuthSource
  def authenticate(_login, _password)
    nil
  end

  def auth_method_name
    'OAuth SSO'
  end

  def self.allow_password_changes?
    false
  end

  def self.sso_source!
    first || create_or_find_by!(name: 'OAuth SSO') do |source|
      source.onthefly_register = false
    end
  end

  # Clear local credentials and revoke tokens before completing SSO sign-in.
  def self.bind!(user)
    source = sso_source!
    if user.new_record?
      user.auth_source = source
      user.hashed_password = ''
      user.salt = ''
      user.password = user.password_confirmation = nil
      user.must_change_passwd = false
    else
      User.transaction do
        # Redmine's User#lock! locks an account and takes no arguments. Lock the
        # database row through the relation instead of calling ActiveRecord's with_lock.
        User.where(id: user.id).lock.load
        user.reload
        if user.auth_source_id == source.id && user.hashed_password.blank? &&
           user.salt.blank? && !user.must_change_passwd?
          Token.where(user_id: user.id, action: 'recovery').delete_all
          return user
        end
        user.update!(auth_source: source, hashed_password: '', salt: '', must_change_passwd: false)
        user.association(:auth_source).reset
        Token.where(user_id: user.id, action: %w[recovery autologin session]).delete_all
      end
    end
    user
  end
end
