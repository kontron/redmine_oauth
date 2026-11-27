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

# Preserve existing email verification behavior on upgrade.
class AddEmailVerificationPolicy < ActiveRecord::Migration[7.2]
  def up
    add_column :oauth_providers, :email_verification_policy, :string, null: false, default: 'reject_unverified'
    execute <<~SQL.squish
      UPDATE #{quote_table_name('oauth_providers')}
      SET email_verification_policy = 'require_verified'
      WHERE require_verified_email = #{connection.quoted_true}
    SQL
    remove_column :oauth_providers, :require_verified_email
  end

  def down
    add_column :oauth_providers, :require_verified_email, :boolean, null: false, default: false
    execute <<~SQL.squish
      UPDATE #{quote_table_name('oauth_providers')}
      SET require_verified_email = #{connection.quoted_true}
      WHERE email_verification_policy <> 'reject_unverified'
    SQL
    remove_column :oauth_providers, :email_verification_policy
  end
end
