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

  def test_oauth_keeps_transient_state_out_of_session
    get "/oauth?oauth_provider=#{@keylock_provider.id}&back_url=/my/account"

    assert_nil session[:oauth_provider]
    assert_nil session[:back_url]
    assert_nil session[:oauth_csrf_token]
    assert_nil session[:code_verifier]
    assert cookies[:redmine_oauth_request_state].present?
  end

  def test_oauth_callback_accepts_state_from_request_cookie
    get "/oauth?oauth_provider=#{@keylock_provider.id}"
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch('state')

    get "/oauth2callback?state=#{state}&code=unused"

    assert_response :found
  end

  def test_oauth_does_not_reflect_provider_id
    get '/oauth', params: { oauth_provider: '<img src=x onerror=alert(1)>' }
    assert_redirected_to signin_path
    assert_equal l(:oauth_invalid_provider), flash[:error]
  end

  def test_oauth_callback_escapes_error_message
    get "/oauth?oauth_provider=#{@keylock_provider.id}"
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch('state')
    OAuth2::Strategy::AuthCode.any_instance.stubs(:get_token).raises(StandardError, '<img src=x onerror=alert(1)>')

    get "/oauth2callback?state=#{state}&code=unused"
    assert_redirected_to signin_path
    follow_redirect!

    assert_select '#flash_error img', 0
    assert_select '#flash_error', text: /<img src=x onerror=alert\(1\)>/
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

  def test_get_uid
    assert_equal 'abc', RedmineOauthController.get_uid({ 'sub' => 'abc' }, @keylock_provider)
    @keylock_provider.oauth_name = 'Azure AD'
    assert_equal 'oid-1', RedmineOauthController.get_uid({ 'oid' => 'oid-1', 'sub' => 'sub-1' }, @keylock_provider)
    @keylock_provider.oauth_name = 'GitHub'
    assert_equal '123', RedmineOauthController.get_uid({ 'id' => 123 }, @keylock_provider)
    assert_raises(StandardError) { RedmineOauthController.get_uid({ 'sub' => 'abc' }, @keylock_provider) }
  end

  def test_find_user_by_uid_linked_identity
    OauthIdentity.create! oauth_provider: @keylock_provider, user: @jsmith, uid: 'uid-1'
    assert_equal @jsmith, RedmineOauthController.find_user_by_uid('uid-1', 'changed@example.com', @keylock_provider)
  end

  def test_find_user_by_uid_auto_link
    @keylock_provider.auto_link_user = true
    assert_equal @jsmith, RedmineOauthController.find_user_by_uid('uid-1', 'JSmith@somenet.foo', @keylock_provider)
    @keylock_provider.auto_link_user = false
    assert_nil RedmineOauthController.find_user_by_uid('uid-1', 'jsmith@somenet.foo', @keylock_provider)
  end

  def test_find_user_by_uid_auto_link_already_linked
    OauthIdentity.create! oauth_provider: @keylock_provider, user: @jsmith, uid: 'uid-1'
    assert_nil RedmineOauthController.find_user_by_uid('uid-2', 'jsmith@somenet.foo', @keylock_provider)
  end

  def test_link_identity
    assert_difference 'OauthIdentity.count', +1 do
      RedmineOauthController.link_identity @jsmith, 'uid-1', @keylock_provider
      RedmineOauthController.link_identity @jsmith, 'uid-1', @keylock_provider
    end
    assert_no_difference 'OauthIdentity.count' do
      RedmineOauthController.link_identity @jsmith, nil, @keylock_provider
    end
  end

  def test_user_matches
    assert RedmineOauthController.user_matches?(@jsmith, 'JSmith@somenet.foo', {}, @keylock_provider)
    assert_not RedmineOauthController.user_matches?(@jsmith, 'dlopper@somenet.foo', {}, @keylock_provider)
    @keylock_provider.identify_user_by = 'login'
    assert RedmineOauthController.user_matches?(@jsmith, nil, { 'login' => 'JSmith' }, @keylock_provider)
    assert_not RedmineOauthController.user_matches?(@jsmith, nil, { 'login' => 'dlopper' }, @keylock_provider)
    assert_not RedmineOauthController.user_matches?(@jsmith, nil, {}, @keylock_provider)
    @keylock_provider.identify_user_by = 'uid'
    OauthIdentity.create! oauth_provider: @keylock_provider, user: @jsmith, uid: 'uid-1'
    assert RedmineOauthController.user_matches?(@jsmith, nil, { 'sub' => 'uid-1' }, @keylock_provider)
    assert_not RedmineOauthController.user_matches?(@jsmith, nil, { 'sub' => 'uid-2' }, @keylock_provider)
  end

  def test_validate_hosted_domain
    google = OauthProvider.new(oauth_name: 'Google', url_parameters: 'prompt=select_account&hd=example.com')
    assert_nothing_raised { RedmineOauthController.validate_hosted_domain({ 'hd' => 'example.com' }, google) }
    assert_raises(StandardError) { RedmineOauthController.validate_hosted_domain({ 'hd' => 'evil.com' }, google) }
    # Personal accounts have no 'hd' claim
    assert_raises(StandardError) { RedmineOauthController.validate_hosted_domain({}, google) }
    google.url_parameters = 'hd=*'
    assert_nothing_raised { RedmineOauthController.validate_hosted_domain({ 'hd' => 'any.com' }, google) }
    assert_raises(StandardError) { RedmineOauthController.validate_hosted_domain({}, google) }
    google.url_parameters = 'xhd=example.com'
    assert_nothing_raised { RedmineOauthController.validate_hosted_domain({}, google) }
    google.url_parameters = nil
    assert_nothing_raised { RedmineOauthController.validate_hosted_domain({}, google) }
  end

  def test_identities_deleted_with_user
    OauthIdentity.create! oauth_provider: @keylock_provider, user: @jsmith, uid: 'uid-1'
    assert_difference 'OauthIdentity.count', -1 do
      @jsmith.destroy
    end
  end
end
