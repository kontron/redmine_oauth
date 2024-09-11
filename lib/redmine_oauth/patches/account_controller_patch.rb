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

module RedmineOauth
  module Patches
    # AccountController patch
    module AccountControllerPatch
      ################################################################################################################
      # Overridden methods
      #
      def logout
        return super if User.current.anonymous? || !request.post? || Setting.plugin_redmine_oauth[:oauth_logout].blank?

        site = Setting.plugin_redmine_oauth[:client_id]
        id = Setting.plugin_redmine_oauth[:client_id]
        url = signin_url
        case Setting.plugin_redmine_oauth[:oauth_name]
        when 'Azure AD'
          logout_user
          redirect_to "#{site}/#{id}/oauth2/logout?post_logout_redirect_uri=#{url}"
        when 'Custom'
          logout_user
          redirect_to Setting.plugin_redmine_oauth[:custom_logout_endpoint]
        when 'GitLab', 'Google'
          Rails.logger.info "#{Setting.plugin_redmine_oauth[:oauth_name]} logout not implement"
          super
        when 'Keycloak'
          logout_user
          redirect_to "#{site}/realms/#{id}/protocol/openid-connect/logout?redirect_uri=#{url}"
        when 'Okta'
          logout_user
          redirect_to "#{site}/oauth2/v1/logout?id_token_hint=#{id}&post_logout_redirect_uri=#{url}"
        else
          super
        end
      rescue StandardError => e
        Rails.logger.error e.message
        flash['error'] = e.message
        redirect_to signin_path
      end
    end
  end
end

AccountController.prepend RedmineOauth::Patches::AccountControllerPatch
