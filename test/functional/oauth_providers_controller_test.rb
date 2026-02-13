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

require File.expand_path('../../integration_test', __FILE__)

# OauthProvidersController class test
class OauthProvidersControllerTest < RedmineOAuth::Test::IntegrationTest
  include Redmine::I18n
  def setup
    super
    @keylock_provider = OauthProvider.find(1)
    @invalid_provider = OauthProvider.find(2)
  end

  def test_index
    # Non-admins not allowed
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/oauth_providers'
    assert_response :forbidden
    post '/logout'

    # Admin is Okay
    post '/login', params: { username: 'admin', password: 'admin' }
    get '/oauth_providers'
    assert_response :success
    assert_select 'h2', { text: l(:label_oauth_providers) }
  end

  def test_new
    post '/login', params: { username: 'admin', password: 'admin' }
    get '/oauth_providers/new'
    assert_response :success
  end

  def test_create
    post '/login', params: { username: 'admin', password: 'admin' }
    assert_difference 'OauthProvider.count', +1 do
      post '/oauth_providers', params: { oauth_provider: {
        oauth_name: 'Test',
        site: 'xxx',
        client_id: 'xxx',
        client_secret: 'xxx',
        tenant_id: 'xxx',
        custom_name: 'Test',
        custom_auth_endpoint: '',
        custom_token_endpoint: '',
        custom_profile_endpoint: '',
        custom_scope: '',
        custom_uid_field: '',
        custom_email_field: '',
        button_color: '',
        button_icon: '',
        custom_firstname_field: '',
        custom_lastname_field: '',
        custom_logout_endpoint: '',
        validate_user_roles: '',
        oauth_version: '2.0',
        identify_user_by: '',
        imap: true
      } }
    end
    assert_redirected_to oauth_providers_path
    # Position updated
    assert_equal OauthProvider.all.size, OauthProvider.sorted.last.position
    # IMAP reset
    assert @keylock_provider.imap
    @keylock_provider.reload
    assert_not @keylock_provider.imap
  end

  def test_create_failed
    post '/login', params: { username: 'admin', password: 'admin' }
    assert_difference 'OauthProvider.count', +0 do
      post '/oauth_providers', params: { oauth_provider: {
        oauth_name: 'Keycloak',
        site: 'xxx',
        client_id: 'xxx',
        client_secret: 'xxx',
        tenant_id: 'xxx',
        custom_name: 'Keycloak',
        custom_auth_endpoint: '',
        custom_token_endpoint: '',
        custom_profile_endpoint: '',
        custom_scope: '',
        custom_uid_field: '',
        custom_email_field: '',
        button_color: '',
        button_icon: '',
        custom_firstname_field: '',
        custom_lastname_field: '',
        custom_logout_endpoint: '',
        validate_user_roles: '',
        oauth_version: '2.0',
        identify_user_by: '',
        imap: false
      } }
    end
    assert_response :success
    assert_select '#errorExplanation', { text: 'Custom name has already been taken' }
  end
end

def test_edit
  post '/login', params: { username: 'admin', password: 'admin' }
  get "/oauth_providers/#{@keylock_provider.id}/edit"
  assert_response :success
end

def test_update
  post '/login', params: { username: 'admin', password: 'admin' }
  patch "/oauth_providers/#{@keylock_provider.id}", params: { oauth_provider: {
    oauth_name: 'Keycloak',
    site: 'https://example.com/sso',
    client_id: 'example-client',
    client_secret: 'florp-burp-durk',
    tenant_id: 'redmine',
    custom_name: 'Keycloak',
    custom_auth_endpoint: '',
    custom_token_endpoint: '',
    custom_profile_endpoint: '',
    custom_scope: '',
    custom_uid_field: '',
    custom_email_field: '',
    button_color: '#ffbe6f',
    button_icon: 'far fa-address-card',
    custom_firstname_field: '',
    custom_lastname_field: '',
    custom_logout_endpoint: '',
    validate_user_roles: '',
    oauth_version: '2.0',
    identify_user_by: '',
    imap: false
  } }
  assert_redirected_to oauth_providers_path
end

def test_update_failed
  post '/login', params: { username: 'admin', password: 'admin' }
  patch "/oauth_providers/#{@invalid_provider.id}", params: { oauth_provider: {
    oauth_name: 'Keycloak',
    site: 'https://example.com/sso',
    client_id: 'example-client',
    client_secret: 'florp-burp-durk',
    tenant_id: 'redmine',
    custom_name: 'Keycloak',
    custom_auth_endpoint: '',
    custom_token_endpoint: '',
    custom_profile_endpoint: '',
    custom_scope: '',
    custom_uid_field: '',
    custom_email_field: '',
    button_color: '#ffbe6f',
    button_icon: 'far fa-address-card',
    custom_firstname_field: '',
    custom_lastname_field: '',
    custom_logout_endpoint: '',
    validate_user_roles: '',
    oauth_version: '2.0',
    identify_user_by: '',
    imap: false
  } }
  assert_response :success
  assert_select '#errorExplanation', { text: 'Custom name has already been taken' }
end

def test_destroy
  post '/login', params: { username: 'admin', password: 'admin' }
  assert_difference 'OauthProvider.count', -1 do
    delete "/oauth_providers/#{@invalid_provider.id}"
  end
  assert_response :success
end
