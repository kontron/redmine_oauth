# frozen_string_literal: true

require File.expand_path('../../integration_test', __FILE__)

class OauthSsoTest < RedmineOAuth::Test::IntegrationTest
  def setup
    super
    @user = User.find_by!(login: 'jsmith')
  end

  def test_migration_disables_password_and_revokes_existing_credentials
    recovery = Token.create!(user: @user, action: 'recovery')
    autologin = Token.create!(user: @user, action: 'autologin')
    session_token = Token.create!(user: @user, action: 'session')
    api = Token.create!(user: @user, action: 'api')
    AuthSourceOauth.bind!(@user)
    assert_instance_of AuthSourceOauth, @user.reload.auth_source
    assert_not @user.check_password?('jsmith')
    assert_not @user.change_password_allowed?
    assert_equal '', @user.hashed_password
    assert_equal '', @user.salt
    assert_not Token.exists?(recovery.id)
    assert_not Token.exists?(autologin.id)
    assert_not Token.exists?(session_token.id)
    assert Token.exists?(api.id)
  end

  def test_repeated_login_keeps_current_sessions
    AuthSourceOauth.bind!(@user)
    token = Token.create!(user: @user, action: 'session')
    AuthSourceOauth.bind!(@user)
    assert Token.exists?(token.id)
  end

  def test_new_user_has_no_password
    user = User.new(login: 'sso-new', firstname: 'New', lastname: 'User', mail: 'sso-new@example.com')
    AuthSourceOauth.bind!(user)
    user.activate
    user.save!
    assert_not user.reload.change_password_allowed?
    assert_equal '', user.hashed_password
  end

  def test_admin_assignment_to_sso_clears_password_and_recovery_tokens
    token = Token.create!(user: @user, action: 'recovery')
    @user.auth_source = AuthSourceOauth.sso_source!
    @user.save!
    assert_equal '', @user.reload.hashed_password
    assert_not Token.exists?(token.id)
  end

  def test_old_recovery_token_cannot_be_consumed
    AuthSourceOauth.bind!(@user)
    token = Token.create!(user: @user, action: 'recovery')
    with_settings lost_password: '1' do
      post '/account/lost_password', params: { token: token.value,
        new_password: 'changed123!', new_password_confirmation: 'changed123!' }
      assert_redirected_to signin_path
    end
    assert_not Token.exists?(token.id)
    assert_equal '', @user.reload.hashed_password
  end

  def test_new_recovery_request_is_refused
    AuthSourceOauth.bind!(@user)
    with_settings lost_password: '1' do
      post '/account/lost_password', params: { mail: @user.mail }
      assert_equal I18n.t(:notice_can_t_change_password), flash[:error]
    end
    assert_not Token.where(user_id: @user.id, action: 'recovery').exists?
  end

  def test_local_administrator_is_untouched
    admin = User.find_by!(login: 'admin')
    original = admin.hashed_password
    AuthSourceOauth.bind!(@user)
    assert_equal original, admin.reload.hashed_password
    assert admin.change_password_allowed?
  end
end
