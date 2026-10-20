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

# Account controller patch test
class AccountControllerTest < RedmineOAuth::Test::IntegrationTest
  def test_login_oauth
    get '/login', headers: { 'HTTP_COOKIE' => 'oauth_autologin=1;' }
    assert_redirected_to oauth_path(oauth_provider: 1)
  end

  def test_login_oauth_nosso
    get '/login?nosso', headers: { 'HTTP_COOKIE' => 'oauth_autologin=1;' }
    assert_response :success
  end

  def test_login
    get '/login'
    assert_response :success
  end

  def test_login_oauth_only_nosso_form_posts_nosso
    with_settings plugin_redmine_oauth: Setting.plugin_redmine_oauth.merge('oauth_only_login' => '1') do
      get '/login?nosso'
      assert_response :success
      assert_includes response.body, '<input type="hidden" name="nosso" value="1">'
    end
  end

  def test_login_oauth_only_nosso_password_post
    with_settings plugin_redmine_oauth: Setting.plugin_redmine_oauth.merge('oauth_only_login' => '1') do
      post '/login', params: { username: 'jsmith', password: 'jsmith', nosso: '1' }
      assert_redirected_to my_page_path
    end
  end

  def test_login_oauth_only_password_post_without_nosso
    with_settings plugin_redmine_oauth: Setting.plugin_redmine_oauth.merge('oauth_only_login' => '1') do
      post '/login', params: { username: 'jsmith', password: 'jsmith' }
      assert_redirected_to oauth_path(oauth_provider: OauthProvider.first.id)
    end
  end

  def test_logout
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    Setting.plugin_redmine_oauth[:oauth_logout] = nil
    post '/logout'
    assert_redirected_to home_path
  end
end
