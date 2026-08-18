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

# OAuth controller test
class RedmineOauthControllerTest < RedmineOAuth::Test::IntegrationTest
  include Redmine::I18n

  def setup
    super
    @keylock_provider = OauthProvider.find(1)
    @invalid_provider = OauthProvider.find(2)
    @jsmith = User.find_by(login: 'jsmith')
    @oauth_provider = OauthProvider.find(1)
  end

  def test_oauth
    get "/oauth?oauth_provider=#{@invalid_provider.id}"
    assert_redirected_to signin_path
    assert_equal l(:oauth_invalid_provider), flash[:error]
  end

  def test_oauth_url_concatenation_for_keycloak
    get "/oauth?oauth_provider=#{@keylock_provider.id}"
    assert_redirected_to(%r{^https://example\.com/sso/realms/redmine/protocol/})
  end

  def test_oauth_callback_csrf
    get '/oauth2callback'
    assert_response :unprocessable_content
  end

  def test_update_user_login
    with_settings plugin_redmine_oauth: { 'update_login' => '0' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'jsmith', @jsmith.login
    end
    with_settings plugin_redmine_oauth: { 'update_login' => '1' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'login', @jsmith.login
    end
  end

  def test_update_user_email
    with_settings plugin_redmine_oauth: { 'update_email' => '0' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'jsmith@somenet.foo', @jsmith.mail
    end
    with_settings plugin_redmine_oauth: { 'update_email' => '1' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'email@example.com', @jsmith.mail
    end
  end

  def test_update_firstname
    with_settings plugin_redmine_oauth: { 'update_firstname' => '0' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'John', @jsmith.firstname
    end
    with_settings plugin_redmine_oauth: { 'update_firstname' => '1' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'firstname', @jsmith.firstname
    end
  end

  def test_update_lastname
    with_settings plugin_redmine_oauth: { 'update_lastname' => '0' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'Smith', @jsmith.lastname
    end
    with_settings plugin_redmine_oauth: { 'update_lastname' => '1' } do
      RedmineOauthController.update_user @jsmith, 'login', 'email@example.com', 'firstname', 'lastname'
      assert_equal 'lastname', @jsmith.lastname
    end
  end

  def test_get_firstname
    info = {
      'name' => 'John Smith'
    }
    assert_equal 'John', RedmineOauthController.get_firstname(info, @oauth_provider)
    info = {
      'name' => 'Jan de Jong'
    }
    assert_equal 'Jan', RedmineOauthController.get_firstname(info, @oauth_provider)
  end

  def test_get_lastname
    info = {
      'name' => 'John Smith'
    }
    assert_equal 'Smith', RedmineOauthController.get_lastname(info, @oauth_provider)
    info = {
      'name' => 'Jan de Jong'
    }
    assert_equal 'de Jong', RedmineOauthController.get_lastname(info, @oauth_provider)
  end
end
