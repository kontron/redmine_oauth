# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Main module
module RedmineOauth
  # Settings
  class << self
    def oauth_name
      if Setting.plugin_redmine_oauth['oauth_name'].present?
        Setting.plugin_redmine_oauth['oauth_name'].strip
      else
        'none'
      end
    end

    def site
      if Setting.plugin_redmine_oauth['site'].present?
        Setting.plugin_redmine_oauth['site'].strip.chomp('/')
      else
        ''
      end
    end

    def client_id
      if Setting.plugin_redmine_oauth['client_id'].present?
        Setting.plugin_redmine_oauth['client_id'].strip
      else
        ''
      end
    end

    def client_secret
      if Setting.plugin_redmine_oauth['client_secret'].present?
        Setting.plugin_redmine_oauth['client_secret'].strip
      else
        ''
      end
    end

    def tenant_id
      if Setting.plugin_redmine_oauth['tenant_id'].present?
        Setting.plugin_redmine_oauth['tenant_id'].strip
      else
        ''
      end
    end

    def custom_name
      if Setting.plugin_redmine_oauth['custom_name'].present?
        Setting.plugin_redmine_oauth['custom_name'].strip
      else
        ''
      end
    end

    def custom_auth_endpoint
      if Setting.plugin_redmine_oauth['custom_auth_endpoint'].present?
        Setting.plugin_redmine_oauth['custom_auth_endpoint'].strip
      else
        ''
      end
    end

    def custom_token_endpoint
      if Setting.plugin_redmine_oauth['custom_token_endpoint'].present?
        Setting.plugin_redmine_oauth['custom_token_endpoint'].strip
      else
        ''
      end
    end

    def custom_profile_endpoint
      if Setting.plugin_redmine_oauth['custom_profile_endpoint'].present?
        Setting.plugin_redmine_oauth['custom_profile_endpoint'].strip
      else
        ''
      end
    end

    def custom_scope
      if Setting.plugin_redmine_oauth['custom_scope'].present?
        Setting.plugin_redmine_oauth['custom_scope'].strip
      else
        ''
      end
    end

    def preferred_username
      if Setting.plugin_redmine_oauth['preferred_username'].present?
        Setting.plugin_redmine_oauth['preferred_username'].strip
      else
        ''
      end
    end

    def email
      if Setting.plugin_redmine_oauth['email'].present?
        Setting.plugin_redmine_oauth['email'].strip
      else
        ''
      end
    end

    def button_color
      if Setting.plugin_redmine_oauth['button_color'].present?
        Setting.plugin_redmine_oauth['button_color'].strip
      else
        '#ffbe6f'
      end
    end

    def button_icon
      if Setting.plugin_redmine_oauth['button_icon'].present?
        Setting.plugin_redmine_oauth['button_icon'].strip
      else
        'fas fa-address-card'
      end
    end

    def hide_login_form?
      value = Setting.plugin_redmine_oauth['hide_login_form']
      value.to_i.positive? || value == 'true'
    end

    def self_registration
      Setting.plugin_redmine_oauth['self_registration'].to_i
    end

    def custom_firstname_field
      if Setting.plugin_redmine_oauth['custom_firstname_field'].present?
        Setting.plugin_redmine_oauth['custom_firstname_field'].strip
      else
        'given_name'
      end
    end

    def custom_lastname_field
      if Setting.plugin_redmine_oauth['custom_lastname_field'].present?
        Setting.plugin_redmine_oauth['custom_lastname_field'].strip
      else
        'family_name'
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

    def custom_logout_endpoint
      if Setting.plugin_redmine_oauth['custom_logout_endpoint'].present?
        Setting.plugin_redmine_oauth['custom_logout_endpoint'].strip
      else
        ''
      end
    end

    def validate_user_roles
      if Setting.plugin_redmine_oauth['validate_user_roles'].present?
        Setting.plugin_redmine_oauth['validate_user_roles'].strip
      else
        ''
      end
    end

    def oauth_version
      if Setting.plugin_redmine_oauth['oauth_version'].present?
        Setting.plugin_redmine_oauth['oauth_version'].strip
      else
        ''
      end
    end

    def custom_uid_field
      if Setting.plugin_redmine_oauth['custom_uid_field'].present?
        Setting.plugin_redmine_oauth['custom_uid_field'].strip
      else
        ''
      end
    end

    def custom_email_field
      if Setting.plugin_redmine_oauth['custom_email_field'].present?
        Setting.plugin_redmine_oauth['custom_email_field'].strip
      else
        ''
      end
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
