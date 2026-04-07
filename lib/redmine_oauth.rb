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

# Main module
module RedmineOauth
  # Settings
  class << self
    def hide_login_form?
      value = Setting.plugin_redmine_oauth['hide_login_form']
      value.to_i.positive? || value == 'true'
    end

    def self_registration
      Setting.plugin_redmine_oauth['self_registration'].to_i
    end

    # Comma-separated domains for self_registration mode 4 (auto-activate if email domain matches).
    def self_registration_domains_list
      raw = Setting.plugin_redmine_oauth['self_registration_domains'].to_s
      raw.split(',').map { |s| s.strip.downcase.delete_prefix('@') }.compact_blank
    end

    # True when email's domain exactly matches or is a subdomain of a listed domain.
    def self_registration_domain_auto_activate?(email)
      return false if self_registration != 4

      email_domain = email.to_s.downcase.split('@', 2).last
      return false if email_domain.blank?

      self_registration_domains_list.any? do |d|
        email_domain == d || email_domain.end_with?(".#{d}")
      end
    end

    def update_login?
      value = Setting.plugin_redmine_oauth['update_login']
      value.to_i.positive? || value == 'true'
    end

    def oauth_logout?
      value = Setting.plugin_redmine_oauth['oauth_logout']
      value.to_i.positive? || value == 'true'
    end

    def oauth_login?
      value = Setting.plugin_redmine_oauth['oauth_login']
      value.to_i.positive? || value == 'true'
    end

    def oauth_only_login?
      value = Setting.plugin_redmine_oauth['oauth_only_login']
      value.to_i.positive? || value == 'true'
    end
  end
end

# Hooks
require File.expand_path('redmine_oauth/hooks/controllers/account_controller_hooks', __dir__)
require File.expand_path('redmine_oauth/hooks/views/base_view_hooks', __dir__)
require File.expand_path('redmine_oauth/hooks/views/login_view_hooks', __dir__)

# Patches
require File.expand_path('redmine_oauth/patches/settings_controller_patch', __dir__)
require File.expand_path('redmine_oauth/patches/account_controller_patch', __dir__)
