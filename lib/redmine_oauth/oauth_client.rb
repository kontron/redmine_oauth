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
  # IMAP
  module OauthClient
    class << self
      def client(oauth_provider)
        case oauth_provider.oauth_name
        when 'Azure AD'
          url = "#{oauth_provider.oauth_version}/"
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: "/#{oauth_provider.tenant_id}/oauth2/#{url}authorize",
            token_url: "/#{oauth_provider.tenant_id}/oauth2/#{url}token"
          )
        when 'GitHub'
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: '/login/oauth/authorize',
            token_url: '/login/oauth/access_token'
          )
        when 'GitLab'
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: '/oauth/authorize',
            token_url: '/oauth/token'
          )
        when 'Google'
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: '/o/oauth2/v2/auth',
            token_url: 'https://oauth2.googleapis.com/token'
          )
        when 'Keycloak'
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: "realms/#{oauth_provider.tenant_id}/protocol/openid-connect/auth",
            token_url: "realms/#{oauth_provider.tenant_id}/protocol/openid-connect/token"
          )
        when 'Okta'
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: "/oauth2/#{oauth_provider.tenant_id}/v1/authorize",
            token_url: "/oauth2/#{oauth_provider.tenant_id}/v1/token"
          )
        when 'Custom'
          OAuth2::Client.new(
            oauth_provider.client_id,
            Redmine::Ciphering.decrypt_text(oauth_provider.client_secret),
            site: oauth_provider.site,
            authorize_url: oauth_provider.custom_auth_endpoint,
            token_url: oauth_provider.custom_token_endpoint
          )
        else
          raise StandardError, l(:oauth_invalid_provider)
        end
      end
    end
  end
end
