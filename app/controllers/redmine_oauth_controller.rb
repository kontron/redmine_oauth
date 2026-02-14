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

require 'account_controller'
require 'jwt'
require 'securerandom'
require 'base64'
require 'digest'

# OAuth controller
class RedmineOauthController < AccountController
  before_action :verify_csrf_token, only: [:oauth_callback]

  def oauth
    # Session
    session[:oauth_provider] = params[:oauth_provider]
    session[:back_url] = params[:back_url]
    session[:autologin] = params[:autologin]
    session[:oauth_autologin] = params[:oauth_provider] if params[:oauth_autologin]
    oauth_csrf_token = generate_csrf_token
    session[:oauth_csrf_token] = oauth_csrf_token

    # Generate PKCE code_verifier and code_challenge
    code_verifier = generate_code_verifier
    session[:code_verifier] = code_verifier
    code_challenge = generate_code_challenge(code_verifier)

    # OAuth provider
    oauth_provider = OauthProvider.find(params[:oauth_provider])

    # Login
    case oauth_provider.oauth_name
    when 'Azure AD'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: case oauth_provider.oauth_version
               when 'v2.0'
                 'openid profile email'
               else
                 'user:email'
               end,
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'GitHub'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'user:email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'GitLab'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'read_user',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Google'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'profile email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Keycloak'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'openid email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Okta'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'openid profile email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Custom'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: oauth_provider.custom_scope,
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    else
      flash['error'] = l(:oauth_invalid_provider)
      redirect_to signin_path
    end
  rescue StandardError => e
    Rails.logger.error e.message
    flash['error'] = e.message
    cookies.delete :oauth_autologin
    redirect_to signin_path
  end

  def oauth_callback
    if params['error'].present?
      Rails.logger.error params['error_description']
      raise StandardError, l(:notice_account_invalid_credentials)
    end

    # Retrieve the PKCE code_verifier from the session
    code_verifier = session.delete(:code_verifier)

    # Provider
    oauth_provider = OauthProvider.find(session[:oauth_provider])

    # Login
    case oauth_provider.oauth_name
    when 'Azure AD'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      id_token = token.params['id_token']
      user_info = JWT.decode(id_token, nil, false).first
      email = user_info['email']
    when 'GitHub'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get('https://api.github.com/user', headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body)
      email = user_info['email']
    when 'GitLab'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get('/api/v4/user', headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body)
      user_info['login'] = user_info['username']
      email = user_info['email']
    when 'Google'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get('https://openidconnect.googleapis.com/v1/userinfo',
                                    headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body)
      user_info['login'] = user_info['email']
      email = user_info['email']
    when 'Keycloak'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      user_info = JWT.decode(token.token, nil, false).first
      user_info['login'] = user_info['preferred_username']
      email = user_info['email']
      session[:oauth_id_token] = token.params[:id_token]
    when 'Okta'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get(
        "/oauth2/#{oauth_provider.tenant_id}/v1/userinfo",
        headers: { 'Accept' => 'application/json' }
      )
      user_info = JSON.parse(userinfo_response.body)
      user_info['login'] = user_info['preferred_username']
      email = user_info['email']
      session[:oauth_id_token] = token.params[:id_token]
    when 'Custom'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      if oauth_provider.custom_profile_endpoint.empty?
        user_info = JWT.decode(token.token, nil, false).first
      else
        userinfo_response = token.get(
          oauth_provider.custom_profile_endpoint,
          headers: { 'Accept' => 'application/json' }
        )
        user_info = JSON.parse(userinfo_response.body)
      end
      user_info['login'] = user_info[oauth_provider.custom_uid_field]
      email = user_info[oauth_provider.custom_email_field]
    else
      raise StandardError, l(:oauth_invalid_provider)
    end
    raise StandardError, l(:oauth_no_verified_email) unless email

    # Roles
    non_default_roles = []
    keys = oauth_provider.validate_user_roles&.split('.')
    if keys&.size&.positive?
      roles = user_info
      while keys.size.positive?
        key = keys.shift
        unless roles.key?(key)
          roles = []
          break
        end
        roles = roles[key]
      end
      roles = roles.to_a
      @admin = roles.include?('admin')
      if roles.blank? || (roles.exclude?('user') && !@admin)
        Rails.logger.info 'Authentication failed due to a missing role in the token'
        params[:username] = email
        invalid_credentials
        raise StandardError, l(:notice_account_invalid_credentials)
      end
      non_default_roles = roles - %w[admin user]
    end

    # Try to log in
    set_params
    try_to_login email, user_info, non_default_roles, oauth_provider
    session[:oauth_login] = oauth_provider.id
  rescue StandardError => e
    Rails.logger.error e.message
    flash['error'] = e.message
    cookies.delete :oauth_autologin
    redirect_to signin_path
  end

  def set_oauth_autologin_cookie
    cookie_options = {
      value: params[:oauth_autologin],
      expires: 1.year.from_now,
      path: RedmineApp::Application.config.relative_url_root || '/',
      same_site: :lax,
      secure: Setting.protocol == 'https',
      httponly: true
    }
    cookies[:oauth_autologin] = cookie_options
  end

  private

  def generate_code_verifier
    SecureRandom.urlsafe_base64(32)
  end

  def generate_code_challenge(code_verifier)
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).delete('=')
  end

  def set_params
    params['back_url'] = session[:back_url]
    session.delete :back_url
    params['autologin'] = session[:autologin]
    session.delete :autologin
    params['oauth_autologin'] = session[:oauth_autologin]
    session.delete :oauth_autologin
  end

  def try_to_login(email, info, role_names, oauth_provider)
    # Login name
    login = info['login']
    login ||= info['unique_name']
    login ||= info['preferred_username']
    # Find the user
    user = case oauth_provider.identify_user_by
           when 'login'
             User.where('LOWER(login) = ?', login.downcase).first
           else
             User.joins(:email_addresses).where('LOWER(email_addresses.address) = ?', email.downcase).first
           end
    if user # Existing user
      if user.registered? # Registered
        account_pending user
      elsif user.active? # Active
        handle_active_user user
        user.update_last_login_on!
        if RedmineOauth.update_login?
          user.login = login
          Rails.logger.error(user.errors.full_messages.to_sentence) unless user.save
        end
        # Disable 2FA initialization request
        session.delete(:must_activate_twofa)
        # Disable password change request
        session.delete(:pwd)
      else # Locked
        handle_inactive_user user
      end
    elsif RedmineOauth.self_registration.positive?
      # Create on the fly
      user = User.new
      user.mail = email
      user.firstname = info[oauth_provider.custom_firstname_field]
      user.lastname = info[oauth_provider.custom_lastname_field]
      first_name, last_name = info['name'].split if info['name'].present?
      user.firstname ||= first_name
      user.lastname ||= last_name
      user.lastname ||= ''
      user.mail = email
      user.login = login
      user.random_password
      user.register
      case RedmineOauth.self_registration
      when 1
        register_by_email_activation(user) do
          onthefly_creation_failed user
        end
      when 3
        register_automatically(user) do
          onthefly_creation_failed user
        end
      else
        register_manually_by_administrator(user) do
          onthefly_creation_failed user
        end
      end
    else # Invalid credentials
      params[:username] = email
      invalid_credentials
      raise StandardError, l(:notice_account_invalid_credentials)
    end

    if oauth_provider.enable_group_roles?
      desired_groups = Group.where(lastname: role_names)
      user.group_ids = desired_groups.ids
    end

    return if @admin.nil?

    user = User.find(user.id)
    Rails.logger.error(user.errors.full_messages.to_sentence) unless user.update(admin: @admin)
  end

  def verify_csrf_token
    if params[:state].blank? || (params[:state] != session[:oauth_csrf_token])
      render_error status: 422, message: l(:error_invalid_authenticity_token)
    end
    session.delete :oauth_csrf_token
  end
end
