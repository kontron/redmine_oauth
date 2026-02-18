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
  version '4.0.2'
  url 'https://github.com/kontron/redmine_oauth'
  author_url 'https://github.com/kontron/redmine_oauth/graphs/contributors'

  requires_redmine version_or_higher: '6.0.0'

  settings default: {
    hide_login_form: '0',
    self_registration: '0',
    update_login: '0',
    oauth_logout: '0',
    oauth_login: '0',
    oauth_only_login: '0'
  }, partial: 'settings/oauth_settings'
end

# Administration menu extension
Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :oauth_providers, { controller: 'oauth_providers', action: 'index' },
            icon: 'apps',
            caption: :label_oauth_providers,
            html: { class: 'icon icon-applications' }
end
