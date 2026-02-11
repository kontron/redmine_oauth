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
class CreateOauthProviders < ActiveRecord::Migration[7.2]
  def up
    create_table :oauth_providers do |t|
      t.string :oauth_name, null: false, default: 'none', limit: 30
      t.string :site, null: false, limit: 40
      t.string :client_id, null: false, limit: 60
      t.string :client_secret, null: false, limit: 128
      t.string :tenant_id, null: false, limit: 40
      t.string :custom_name, null: false, limit: 30
      t.string :custom_auth_endpoint, null: true, limit: 80
      t.string :custom_token_endpoint, null: true, limit: 80
      t.string :custom_profile_endpoint, null: true, limit: 80
      t.string :custom_scope, null: true, default: 'openid profile email', limit: 40
      t.string :custom_uid_field, null: true, default: 'preferred_username', limit: 40
      t.string :custom_email_field, null: true, default: 'email', limit: 40
      t.string :button_color, null: false, default: '#ffbe6f', limit: 7
      t.string :button_icon, null: false, default: 'fas fa-address-card', limit: 30
      t.string :custom_firstname_field, null: true, default: 'given_name', limit: 30
      t.string :custom_lastname_field, null: true, default: 'family_name', limit: 30
      t.string :custom_logout_endpoint, null: true, limit: 80
      t.string :validate_user_roles, null: true, limit: 40
      t.string :oauth_version, null: true, limit: 4
      t.string :identify_user_by, null: true, default: 'email', limit: 5
      t.boolean :imap, null: false, default: false
      t.integer :position, null: true, default: 1
      t.timestamps
      t.index :custom_name, unique: true
      t.index :imap
    end
    settings_to_table
  end

  def down
    table_to_settings
    drop_table :oauth_providers
  end

  private

  def settings_to_table
    return if Setting.plugin_redmine_oauth['oauth_name'].blank?

    oauth_provider = OauthProvider.new
    oauth_provider.oauth_name = Setting.plugin_redmine_oauth['oauth_name']
    oauth_provider.site = Setting.plugin_redmine_oauth['site']
    oauth_provider.client_id = Setting.plugin_redmine_oauth['client_id']
    oauth_provider.client_secret = Setting.plugin_redmine_oauth['client_secret']
    oauth_provider.tenant_id = Setting.plugin_redmine_oauth['tenant_id']
    oauth_provider.custom_name = Setting.plugin_redmine_oauth['custom_name']
    oauth_provider.custom_auth_endpoint = Setting.plugin_redmine_oauth['custom_auth_endpoint']
    oauth_provider.custom_token_endpoint = Setting.plugin_redmine_oauth['custom_token_endpoint']
    oauth_provider.custom_profile_endpoint = Setting.plugin_redmine_oauth['custom_profile_endpoint']
    oauth_provider.custom_scope = Setting.plugin_redmine_oauth['custom_scope']
    oauth_provider.custom_uid_field = Setting.plugin_redmine_oauth['custom_uid_field']
    oauth_provider.custom_email_field = Setting.plugin_redmine_oauth['custom_email_field']
    oauth_provider.button_color = Setting.plugin_redmine_oauth['button_color']
    oauth_provider.button_icon = Setting.plugin_redmine_oauth['button_icon']
    oauth_provider.custom_firstname_field = Setting.plugin_redmine_oauth['custom_firstname_field']
    oauth_provider.custom_lastname_field = Setting.plugin_redmine_oauth['custom_lastname_field']
    oauth_provider.custom_logout_endpoint = Setting.plugin_redmine_oauth['custom_logout_endpoint']
    oauth_provider.validate_user_roles = Setting.plugin_redmine_oauth['validate_user_roles']
    oauth_provider.oauth_version = Setting.plugin_redmine_oauth['oauth_version']
    oauth_provider.identify_user_by = Setting.plugin_redmine_oauth['identify_user_by']
    oauth_provider.imap = true
    oauth_provider.position = 1
    oauth_provider.save!
  end

  def table_to_settings
    oauth_provider = OauthProvider.first
    return unless oauth_provider

    Setting.plugin_redmine_oauth['oauth_name'] = oauth_provider.oauth_name
    Setting.plugin_redmine_oauth['site'] = oauth_provider.site
    Setting.plugin_redmine_oauth['client_id'] = oauth_provider.client_id
    Setting.plugin_redmine_oauth['client_secret'] = oauth_provider.client_secret
    Setting.plugin_redmine_oauth['tenant_id'] = oauth_provider.tenant_id
    Setting.plugin_redmine_oauth['custom_name'] = oauth_provider.custom_name
    Setting.plugin_redmine_oauth['custom_auth_endpoint'] = oauth_provider.custom_auth_endpoint
    Setting.plugin_redmine_oauth['custom_token_endpoint'] = oauth_provider.custom_token_endpoint
    Setting.plugin_redmine_oauth['custom_profile_endpoint'] = oauth_provider.custom_profile_endpoint
    Setting.plugin_redmine_oauth['custom_scope'] = oauth_provider.custom_scope
    Setting.plugin_redmine_oauth['custom_uid_field'] = oauth_provider.custom_uid_field
    Setting.plugin_redmine_oauth['custom_email_field'] = oauth_provider.custom_email_field
    Setting.plugin_redmine_oauth['button_color'] = oauth_provider.button_color
    Setting.plugin_redmine_oauth['button_icon'] = oauth_provider.button_icon
    Setting.plugin_redmine_oauth['custom_firstname_field'] = oauth_provider.custom_firstname_field
    Setting.plugin_redmine_oauth['custom_lastname_field'] = oauth_provider.custom_lastname_field
    Setting.plugin_redmine_oauth['custom_logout_endpoint'] = oauth_provider.custom_logout_endpoint
    Setting.plugin_redmine_oauth['validate_user_roles'] = oauth_provider.validate_user_roles
    Setting.plugin_redmine_oauth['oauth_version'] = oauth_provider.oauth_version
    Setting.plugin_redmine_oauth['identify_user_by'] = oauth_provider.identify_user_by
  end
end
