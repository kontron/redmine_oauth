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

module RedmineOauth
  module Hooks
    module Views
      # Base view hooks
      class BaseViewHooks < Redmine::Hook::ViewListener
        def view_layouts_base_html_head(context = {})
          unless /^(AccountController|SettingsController|RedmineOauthController|OauthProvidersController)/.match?(
            context[:controller].class.name
          )
            return
          end

          "\n".html_safe + stylesheet_link_tag('redmine_oauth', plugin: :redmine_oauth) +
            "\n".html_safe + stylesheet_link_tag('fontawesome/all.min', plugin: :redmine_oauth) +
            "\n".html_safe + javascript_include_tag('redmine_oauth', plugin: :redmine_oauth)
        end
      end
    end
  end
end
