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

require 'redmine'
require "#{File.dirname(__FILE__)}/lib/redmine_oauth"

Redmine::Plugin.register :redmine_oauth do
  name 'Redmine OAuth plugin'
  author 'Karel Pičman'
  description 'Redmine OAuth plugin'
  version '3.0.9 devel'
  url 'https://github.com/kontron/redmine_oauth'
  author_url 'https://github.com/kontron/redmine_oauth/graphs/contributors'

  requires_redmine version_or_higher: '6.0.0'

  settings default: {
    oauth_name: 'none',
    site: '',
    client_id: '',
    client_secret: '',
    tenant_id: '',
    custom_name: '',
    custom_auth_endpoint: '',
    custom_token_endpoint: '',
    custom_profile_endpoint: '',
    custom_scope: 'openid profile email',
    custom_uid_field: 'preferred_username',
    custom_email_field: 'email',
    button_color: '#ffbe6f',
    button_icon: 'fas fa-address-card',
    hide_login_form: '0',
    self_registration: '0',
    custom_firstname_field: 'given_name',
    custom_lastname_field: 'family_name',
    update_login: '0',
    oauth_logout: '0',
    oauth_login: '0',
    custom_logout_endpoint: '',
    validate_user_roles: '',
    oauth_version: 'v2.0',
    identify_user_by: 'email'
  }, partial: 'settings/oauth_settings'
end
