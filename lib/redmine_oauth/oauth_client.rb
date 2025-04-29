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
  # IMAP
  module OauthClient
    class << self
      def client
        site = RedmineOauth.site
        raise StandardError, l(:oauth_invalid_provider) unless site

        case RedmineOauth.oauth_name
        when 'Azure AD'
          url = RedmineOauth.oauth_version.present? ? "#{RedmineOauth.oauth_version}/" : ''
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: "/#{RedmineOauth.tenant_id}/oauth2/#{url}authorize",
            token_url: "/#{RedmineOauth.tenant_id}/oauth2/#{url}token"
          )
        when 'GitHub'
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: '/login/oauth/authorize',
            token_url: '/login/oauth/access_token'
          )
        when 'GitLab'
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: '/oauth/authorize',
            token_url: '/oauth/token'
          )
        when 'Google'
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: '/o/oauth2/v2/auth',
            token_url: 'https://oauth2.googleapis.com/token'
          )
        when 'Keycloak'
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: "/realms/#{RedmineOauth.tenant_id}/protocol/openid-connect/auth",
            token_url: "/realms/#{RedmineOauth.tenant_id}/protocol/openid-connect/token"
          )
        when 'Okta'
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: "/oauth2/#{RedmineOauth.tenant_id}/v1/authorize",
            token_url: "/oauth2/#{RedmineOauth.tenant_id}/v1/token"
          )
        when 'Custom'
          OAuth2::Client.new(
            RedmineOauth.client_id,
            Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
            site: site,
            authorize_url: RedmineOauth.custom_auth_endpoint,
            token_url: RedmineOauth.custom_token_endpoint
          )
        else
          raise StandardError, l(:oauth_invalid_provider)
        end
      end
    end
  end
end
