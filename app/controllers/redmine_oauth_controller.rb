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

require 'account_controller'
require 'jwt'
require 'securerandom'
require 'base64'
require 'digest'

# OAuth controller
class RedmineOauthController < AccountController
  before_action :verify_csrf_token, only: [:oauth_callback]

  def oauth
    session[:back_url] = params[:back_url]
    session[:autologin] = params[:autologin]
    session[:oauth_autologin] = params[:oauth_autologin]
    oauth_csrf_token = generate_csrf_token
    session[:oauth_csrf_token] = oauth_csrf_token

    # Generate PKCE code_verifier and code_challenge
    code_verifier = generate_code_verifier
    session[:code_verifier] = code_verifier
    code_challenge = generate_code_challenge(code_verifier)

    case RedmineOauth.oauth_name
    when 'Azure AD'
      redirect_to oauth_client.auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: case RedmineOauth.oauth_version
               when 'v2.0'
                 'openid profile email'
               else
                 'user:email'
               end,
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'GitLab'
      redirect_to oauth_client.auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'read_user',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Google'
      redirect_to oauth_client.auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'profile email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Keycloak'
      redirect_to oauth_client.auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'openid email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Okta'
      redirect_to oauth_client.auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: 'openid profile email',
        code_challenge: code_challenge,
        code_challenge_method: 'S256'
      )
    when 'Custom'
      redirect_to oauth_client.auth_code.authorize_url(
        redirect_uri: oauth_callback_url,
        state: oauth_csrf_token,
        scope: RedmineOauth.custom_scope,
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
    redirect_to signin_path
  end

  def oauth_callback
    if params['error'].present?
      Rails.logger.error params['error_description']
      raise StandardError, l(:notice_account_invalid_credentials)
    end

    # Retrieve the PKCE code_verifier from the session
    code_verifier = session.delete(:code_verifier)

    case RedmineOauth.oauth_name
    when 'Azure AD'
      token = oauth_client.auth_code.get_token(params['code'],
                                               redirect_uri: oauth_callback_url,
                                               code_verifier: code_verifier)
      user_info = JWT.decode(token.token, nil, false).first
      email = user_info['unique_name']
    when 'GitLab'
      token = oauth_client.auth_code.get_token(params['code'],
                                               redirect_uri: oauth_callback_url,
                                               code_verifier: code_verifier)
      userinfo_response = token.get('/api/v4/user', headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body)
      user_info['login'] = user_info['username']
      email = user_info['email']
    when 'Google'
      token = oauth_client.auth_code.get_token(params['code'],
                                               redirect_uri: oauth_callback_url,
                                               code_verifier: code_verifier)
      userinfo_response = token.get('https://openidconnect.googleapis.com/v1/userinfo',
                                    headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body)
      user_info['login'] = user_info['email']
      email = user_info['email']
    when 'Keycloak'
      token = oauth_client.auth_code.get_token(params['code'],
                                               redirect_uri: oauth_callback_url,
                                               code_verifier: code_verifier)
      user_info = JWT.decode(token.token, nil, false).first
      user_info['login'] = user_info['preferred_username']
      email = user_info['email']
    when 'Okta'
      token = oauth_client.auth_code.get_token(params['code'],
                                               redirect_uri: oauth_callback_url,
                                               code_verifier: code_verifier)
      userinfo_response = token.get(
        "/oauth2/#{RedmineOauth.tenant_id}/v1/userinfo",
        headers: { 'Accept' => 'application/json' }
      )
      user_info = JSON.parse(userinfo_response.body)
      user_info['login'] = user_info['preferred_username']
      email = user_info['email']
    when 'Custom'
      token = oauth_client.auth_code.get_token(params['code'],
                                               redirect_uri: oauth_callback_url,
                                               code_verifier: code_verifier)
      if RedmineOauth.custom_profile_endpoint.empty?
        user_info = JWT.decode(token.token, nil, false).first
      else
        userinfo_response = token.get(
          RedmineOauth.custom_profile_endpoint,
          headers: { 'Accept' => 'application/json' }
        )
        user_info = JSON.parse(userinfo_response.body)
      end
      user_info['login'] = user_info[RedmineOauth.custom_uid_field]
      email = user_info[RedmineOauth.custom_email_field]
    else
      raise StandardError, l(:oauth_invalid_provider)
    end
    raise StandardError, l(:oauth_no_verified_email) unless email

    # Roles
    keys = RedmineOauth.validate_user_roles.split('.')
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
    end

    # Try to log in
    set_params
    try_to_login email, user_info
    session[:oauth_login] = true
  rescue StandardError => e
    Rails.logger.error e.message
    flash['error'] = e.message
    cookies.delete :oauth_autologin
    redirect_to signin_path
  end

  def set_oauth_autologin_cookie
    cookie_options = {
      value: '1',
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

  def try_to_login(email, info)
    user = User.joins(:email_addresses).where(email_addresses: { address: email }).first
    if user # Existing user
      if user.registered? # Registered
        account_pending user
      elsif user.active? # Active
        handle_active_user user
        user.update_last_login_on!
        if RedmineOauth.update_login? && (info['login'] || info['unique_name'])
          user.login = info['login'] || info['unique_name']
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
      firstname, lastname = info['name'].split if info['name'].present?
      key = RedmineOauth.custom_firstname_field
      firstname ||= info[key]
      user.firstname = firstname
      key = RedmineOauth.custom_lastname_field
      lastname ||= info[key]
      user.lastname = lastname
      user.mail = email
      login = info['login']
      login ||= info['unique_name']
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
    return if @admin.nil?

    user.admin = @admin
    Rails.logger.error(user.errors.full_messages.to_sentence) unless user.save
  end

  def oauth_client
    return @client if @client

    site = RedmineOauth.site
    raise StandardError, l(:oauth_invalid_provider) unless site

    @client =
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

  def verify_csrf_token
    if params[:state].blank? || (params[:state] != session[:oauth_csrf_token])
      render_error status: 422, message: l(:error_invalid_authenticity_token)
    end
    session.delete :oauth_csrf_token
  end
end
