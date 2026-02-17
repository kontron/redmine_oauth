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

# OauthProviders DB migration
class UrlParameters < ActiveRecord::Migration[7.2]
  def up
    remove_column :oauth_providers, :hd
    remove_column :oauth_providers, :access_type
    add_column :oauth_providers, :url_parameters, :string, null: true, limit: 128
  end

  def down
    remove_column :oauth_providers, :url_parameters
    add_column :oauth_providers, :hd, :string, null: true, limit: 40
    add_column :oauth_providers, :access_type, :string, null: true, limit: 7
  end
end
