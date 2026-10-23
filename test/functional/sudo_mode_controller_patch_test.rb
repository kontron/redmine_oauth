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

# SudoModeController patch test
class SudoModeControllerPatchTest < RedmineOAuth::Test::IntegrationTest
  def setup
    super
    Redmine::SudoMode.stubs(:enabled?).returns(true)
    @oauth_provider = OauthProvider.find(1)
  end

  def test_sudo_mode_required_for_xhr
    log_user 'admin', 'admin'
    expire_sudo_mode!
    assert_no_difference 'Member.count' do
      post '/projects/ecookbook/memberships', params: { membership: { role_ids: [1], user_id: 7 } }, xhr: true
    end
  end

  def test_reauthentication
    log_user_via_oauth 'jsmith'
    expire_sudo_mode!
    request_reauthentication
    stub_oauth_token 'jsmith'
    get "/oauth2callback?state=#{oauth_state}&code=unused"
    assert_response :success
    assert session[:oauth_sudo_mode_ok]
    post '/my/api_key'
    assert_redirected_to '/my/account'
  end

  def test_reauthentication_with_invalid_code
    log_user_via_oauth 'jsmith'
    expire_sudo_mode!
    request_reauthentication
    OAuth2::Strategy::AuthCode.any_instance.stubs(:get_token).raises(StandardError, 'invalid_grant')
    get "/oauth2callback?state=#{oauth_state}&code=forged"
    assert_redirected_to signin_path
    assert_nil session[:oauth_sudo_mode_ok]
  end

  def test_reauthentication_as_another_user
    log_user_via_oauth 'jsmith'
    expire_sudo_mode!
    request_reauthentication
    stub_oauth_token 'dlopper'
    get "/oauth2callback?state=#{oauth_state}&code=unused"
    assert_redirected_to signin_path
    assert_nil session[:oauth_sudo_mode_ok]
    assert_equal @user_id, session[:user_id]
  end

  def test_reauthentication_with_another_provider
    other_provider = @oauth_provider.dup
    other_provider.custom_name = 'Other'
    other_provider.save!
    log_user_via_oauth 'jsmith'
    expire_sudo_mode!
    post '/my/api_key'
    get "/oauth?oauth_provider=#{other_provider.id}&reauth=true"
    stub_oauth_token 'jsmith'
    get "/oauth2callback?state=#{oauth_state}&code=unused"
    assert_redirected_to signin_path
    assert_nil session[:oauth_sudo_mode_ok]
  end

  private

  def log_user_via_oauth(login)
    oauth_login login
    @user_id = User.find_by(login: login).id
    assert_equal @user_id, session[:user_id]
    assert_equal @oauth_provider.id, session[:oauth_login]
  end

  def request_reauthentication
    post '/my/api_key'
    assert_redirected_to(%r{/oauth\?})
    follow_redirect!
    assert_redirected_to(%r{^https://example\.com/sso/})
  end

  def expire_sudo_mode!
    travel_to 20.minutes.from_now
  end
end
