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

# OauthIdentities DB migration
class CreateOauthIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_identities do |t|
      t.integer :oauth_provider_id, null: false
      t.integer :user_id, null: false
      t.string :uid, null: false
      t.timestamps
    end
    add_index :oauth_identities, %i[oauth_provider_id uid], unique: true
    add_index :oauth_identities, %i[oauth_provider_id user_id], unique: true
    add_index :oauth_identities, :user_id
    add_column :oauth_providers, :auto_link_user, :boolean, null: false, default: true
  end
end
