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

using DataFlattener
require 'account_controller'
require 'jwt'
require 'securerandom'
require 'base64'
require 'digest'

# OAuth controller
class RedmineOauthController < AccountController
  before_action :verify_csrf_token, only: [:oauth_callback]

  OAUTH_REQUEST_STATE_COOKIE = :redmine_oauth_request_state

  def oauth
    oauth_csrf_token = generate_csrf_token
    # params - back_url, _method, commit, oauth_provider, controller, action
    # Generate PKCE code_verifier and code_challenge
    code_verifier = generate_code_verifier
    code_challenge = generate_code_challenge(code_verifier)
    oauth_request_state = {
      oauth_provider: params[:oauth_provider],
      back_url: params[:back_url],
      autologin: params[:autologin],
      csrf_token: oauth_csrf_token,
      code_verifier: code_verifier
    }
    oauth_request_state[:oauth_autologin] = params[:oauth_provider] if params[:oauth_autologin]
    store_oauth_request_state oauth_request_state
    # OAuth provider
    oauth_provider = OauthProvider.find_by(id: params[:oauth_provider])

    # Login
    case oauth_provider&.oauth_name
    when 'Azure AD'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: case oauth_provider.oauth_version
                 when 'v2.0'
                   'openid profile email'
                 else
                   'user:email'
                 end,
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
    when 'GitHub'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: 'user:email',
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
    when 'GitLab'
      url = RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: 'read_user',
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
      url << "&#{oauth_provider.url_parameters}" if oauth_provider.url_parameters.present?
      redirect_to url
    when 'Google'
      url = RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: 'profile email',
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
      url << "&#{oauth_provider.url_parameters}" if oauth_provider.url_parameters.present?
      redirect_to url
    when 'Keycloak'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: 'openid email',
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
    when 'Okta'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: 'openid profile email',
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
    when 'Custom'
      redirect_to RedmineOauth::OauthClient.client(oauth_provider).auth_code.authorize_url(
        {
          redirect_uri: oauth_callback_url,
          state: oauth_csrf_token,
          scope: oauth_provider.custom_scope,
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          max_age: params[:reauth] ? 0 : nil
        }.compact
      )
    else
      flash['error'] = l(:oauth_invalid_provider)
      redirect_to signin_path
    end
  rescue StandardError => e
    Rails.logger.error e.message
    flash['error'] = ERB::Util.html_escape(e.message)
    clear_oauth_request_state oauth_csrf_token
    cookies.delete :oauth_autologin
    redirect_to signin_path
  end

  def oauth_callback
    request_state = oauth_request_state

    if params['error'].present?
      Rails.logger.error "OAuth error: #{params['error']} #{params['error_description']}".squish
      raise StandardError, l(:notice_account_invalid_credentials)
    end

    # Retrieve the PKCE code verifier from the OAuth request state.
    code_verifier = request_state[:code_verifier]
    clear_oauth_request_state

    # Provider
    oauth_provider = OauthProvider.find(request_state[:oauth_provider])
    email, user_info = fetch_user_info(oauth_provider, code_verifier)
    raise StandardError, l(:oauth_no_verified_email) unless email

    restricted_user = RedmineOauthController.validate_email_verified(user_info, oauth_provider)
    sudo_reauthentication = session.key?(:oauth_sudo_mode) && User.current.logged?
    oauth_sudo_mode = session.delete(:oauth_sudo_mode) if sudo_reauthentication

    # Roles
    non_default_roles = []
    key = oauth_provider.validate_user_roles
    if key.present? && (!sudo_reauthentication || restricted_user)
      roles = if (h = user_info.select { |k, _v| k =~ /\A#{Regexp.escape(key)}(\.(\d+))?\z/ })
                h.values
              else
                []
              end
      @admin = roles.include?('admin')
      if roles.blank? || (roles.exclude?('user') && !@admin)
        Rails.logger.info 'Authentication failed due to a missing role in the token'
        params[:username] = restricted_user ? restricted_user.login : email
        invalid_credentials
        raise StandardError, l(:notice_account_invalid_credentials)
      end
      non_default_roles = roles - %w[admin user]
    end

    # Re-authentication for the sudo mode, the identity must belong to the current user
    if sudo_reauthentication
      same_user = if restricted_user
                    restricted_user == User.current
                  else
                    RedmineOauthController.user_matches?(User.current, email, user_info, oauth_provider)
                  end
      role_matches = !restricted_user || key.blank? || !User.current.admin? || @admin
      unless oauth_provider.id == session[:oauth_login] && same_user && role_matches
        Rails.logger.error "Sudo mode re-authentication of #{User.current.login} failed"
        raise StandardError, l(:notice_account_invalid_credentials)
      end
      session[:oauth_sudo_mode_ok] = true
      repost oauth_sudo_mode[:back_url], params: oauth_sudo_mode[:params], options: oauth_sudo_mode[:options]
      return
    end

    # Try to log in
    apply_request_state request_state
    try_to_login email, user_info, non_default_roles, oauth_provider, restricted_user: restricted_user
    session[:oauth_login] = oauth_provider.id
  rescue StandardError => e
    Rails.logger.error e.message
    flash['error'] = ERB::Util.html_escape(e.message)
    cookies.delete :oauth_autologin
    redirect_to signin_path
  end

  # Update user's profile with data from OAuth provider
  def self.update_user(user, login, email, firstname, lastname)
    user.login = login if login && RedmineOauth.update_login?
    user.mail = email if email && RedmineOauth.update_email?
    user.firstname = firstname if RedmineOauth.update_firstname?
    user.lastname = lastname if RedmineOauth.update_lastname?
    Rails.logger.error(user.errors.full_messages.to_sentence) unless user.save
  end

  # Get the provider's immutable user ID from OAuth data
  def self.get_uid(info, oauth_provider)
    uid = case oauth_provider.oauth_name
          when 'Azure AD'
            info['oid'] || info['sub']
          when 'GitHub', 'GitLab'
            info['id']
          else
            info['sub']
          end
    raise StandardError, ::I18n.t(:oauth_no_uid) if uid.blank?

    uid.to_s
  end

  # Find the user by their OAuth identity, optionally linking an existing user with the same email on the first login
  def self.find_user_by_uid(uid, email, oauth_provider)
    identity = OauthIdentity.find_by(oauth_provider_id: oauth_provider.id, uid: uid)
    return identity.user if identity
    return nil unless oauth_provider.auto_link_user?

    user = User.joins(:email_addresses).where('LOWER(email_addresses.address) = ?', email.downcase).first
    # The user is already linked with another identity of this provider
    return nil if user && OauthIdentity.exists?(oauth_provider_id: oauth_provider.id, user_id: user.id)

    user
  end

  # Store the link between the user and their OAuth identity
  def self.link_identity(user, uid, oauth_provider)
    return if uid.blank?

    OauthProvider.transaction do
      current_provider = OauthProvider.lock.find(oauth_provider.id)
      unless current_provider.uid_namespace == oauth_provider.uid_namespace
        raise StandardError, ::I18n.t(:notice_account_invalid_credentials)
      end

      current_provider.oauth_identities.find_or_create_by!(uid: uid) do |identity|
        identity.user = user
      end
    end
  end

  # Get the login name from OAuth data
  def self.get_login(info)
    info['login'] || info['unique_name'] || info['preferred_username']
  end

  # Check whether the OAuth data identify the given user
  def self.user_matches?(user, email, info, oauth_provider)
    case oauth_provider.identify_user_by
    when 'login'
      user.login.casecmp?(get_login(info).to_s)
    when 'uid'
      OauthIdentity.exists?(oauth_provider_id: oauth_provider.id, uid: get_uid(info, oauth_provider), user_id: user.id)
    else
      user.email_addresses.exists?(['LOWER(address) = ?', email.downcase])
    end
  end

  # Check the hosted domain required by the 'hd' URL parameter (Google). The 'hd' URL parameter is only a hint for the
  # provider, so the claim must be present and match; personal accounts without the claim are rejected.
  def self.validate_hosted_domain(info, oauth_provider)
    return unless oauth_provider.url_parameters =~ /(?:\A|&)hd=([^&]*)/

    hd = Regexp.last_match(1)
    return if info['hd'].present? && (hd == '*' || info['hd'].casecmp?(hd))

    raise StandardError, ::I18n.t(:error_invalid_hosted_domain)
  end

  # Return the existing account when accepting an unverified email under a restricted policy.
  def self.validate_email_verified(info, oauth_provider)
    return if OauthProvider::EMAIL_VERIFIED_CLAIM_PROVIDERS.exclude?(oauth_provider.oauth_name)

    verified = info['email_verified']
    # Some providers send the value as a string
    return if verified.to_s == 'true'

    return if verified.nil? && oauth_provider.email_verification_policy == 'reject_unverified'

    if !info.key?('email_verified') || [false, 'false'].include?(verified)
      user = restricted_email_user(info, oauth_provider)
      return user if user&.active?
    end

    raise StandardError, ::I18n.t(:oauth_unverified_email)
  end

  def self.restricted_email_user(info, oauth_provider)
    case oauth_provider.email_verification_policy
    when 'allow_linked_uid'
      return unless oauth_provider.identify_user_by == 'uid'

      uid = get_uid(info, oauth_provider)
      identity = oauth_provider.oauth_identities.find_by(uid: uid)
      # Some database collations compare identifiers case-insensitively.
      identity.user if identity&.uid == uid
    when 'allow_managed_login'
      return unless oauth_provider.identify_user_by == 'login' &&
                    OauthProvider::MANAGED_LOGIN_PROVIDERS.include?(oauth_provider.oauth_name)

      login = info['preferred_username']
      # Do not fall back to another claim or accept an email address as a login.
      return unless login.is_a?(String) && login.present? && login.exclude?('@')

      user = User.find_by('LOWER(login) = ?', login.downcase)
      # Database collations can also ignore accents or other differences.
      user if user && user.login.downcase == login.downcase
    end
  end
  private_class_method :restricted_email_user

  # Check that the token was issued for this application; the tokens come directly from the provider's token endpoint
  # over TLS, so their signature is not verified
  def self.validate_audience(audience, oauth_provider)
    return if Array(audience).include?(oauth_provider.client_id)

    raise StandardError, ::I18n.t(:notice_account_invalid_credentials)
  end

  # Get the first name from for OAuth data
  def self.get_firstname(info, oauth_provider)
    firstname = info[oauth_provider.custom_firstname_field]
    firstname, = info['name'].split(' ', 2) if info['name'].present? && firstname.blank?
    firstname
  end

  # Get the last name from for OAuth data
  def self.get_lastname(info, oauth_provider)
    lastname = info[oauth_provider.custom_lastname_field]
    _, lastname = info['name'].split(' ', 2) if info['name'].present? && lastname.blank?
    lastname ||= ''
    lastname
  end

  private

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

  def generate_code_verifier
    SecureRandom.urlsafe_base64 32
  end

  def generate_code_challenge(code_verifier)
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).delete '='
  end

  def apply_request_state(oauth_request_state)
    params['back_url'] = oauth_request_state[:back_url]
    params['autologin'] = oauth_request_state[:autologin]
    params['oauth_autologin'] = oauth_request_state[:oauth_autologin]
  end

  def try_to_login(email, info, role_names, oauth_provider, restricted_user: nil)
    # Login name
    login = RedmineOauthController.get_login(info)
    firstname = RedmineOauthController.get_firstname(info, oauth_provider)
    lastname = RedmineOauthController.get_lastname(info, oauth_provider)
    if !restricted_user && oauth_provider.identify_user_by == 'uid'
      uid = RedmineOauthController.get_uid(info, oauth_provider)
    end
    # Find the user
    user = restricted_user || find_oauth_user(email, login, uid, oauth_provider)
    RedmineOauthController.link_identity(user, uid, oauth_provider) if user && !restricted_user
    if user # Existing user
      if user.registered? # Registered
        account_pending user
        return
      elsif user.active? # Active
        # Keep existing administrator accounts local unless explicitly migrated.
        AuthSourceOauth.bind!(user) if RedmineOauth.disable_local_passwords? && !user.admin?
        handle_active_user user
        user.update_last_login_on!
        # A provider may also use the unverified address as the login name.
        RedmineOauthController.update_user user, (restricted_user ? nil : login), (restricted_user ? nil : email),
                                           firstname, lastname
        # Disable 2FA initialization request
        session.delete(:must_activate_twofa)
        # Disable password change request
        session.delete(:pwd)
      else # Locked
        handle_inactive_user user
        return
      end
    elsif RedmineOauth.self_registration.positive?
      # Create on the fly
      user = User.new
      user.mail = email
      user.firstname = firstname
      user.lastname = lastname
      user.mail = email
      user.login = login
      if RedmineOauth.disable_local_passwords?
        AuthSourceOauth.bind!(user)
      else
        user.random_password
      end
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
      when 4
        if RedmineOauth.self_registration_domain_auto_activate?(email)
          register_automatically(user) do
            onthefly_creation_failed user
          end
        else
          register_manually_by_administrator(user) do
            onthefly_creation_failed user
          end
        end
      else
        register_manually_by_administrator(user) do
          onthefly_creation_failed user
        end
      end
      # Link the newly registered user with their OAuth identity
      RedmineOauthController.link_identity(user, uid, oauth_provider) if user.persisted?
    else # Invalid credentials
      params[:username] = email
      invalid_credentials
      raise StandardError, l(:notice_account_invalid_credentials)
    end

    # Groups and admin rights only for active accounts, not for those waiting for an activation
    return unless user.persisted? && user.active?

    if oauth_provider.enable_group_roles?
      desired_groups = Group.where(lastname: role_names)
      user.group_ids = desired_groups.ids
    end

    return if @admin.nil?

    user = User.find(user.id)
    Rails.logger.error(user.errors.full_messages.to_sentence) unless user.update(admin: @admin)
  end

  def find_oauth_user(email, login, uid, oauth_provider)
    case oauth_provider.identify_user_by
    when 'login'
      User.where('LOWER(login) = ?', login.downcase).first
    when 'uid'
      RedmineOauthController.find_user_by_uid uid, email, oauth_provider
    else
      User.joins(:email_addresses).where('LOWER(email_addresses.address) = ?', email.downcase).first
    end
  end

  def verify_csrf_token
    return unless params[:state].blank? || (params[:state] != oauth_request_state[:csrf_token])

    clear_oauth_request_state
    render_error status: 422, message: l(:error_invalid_authenticity_token)
  end

  # Each OAuth request has its own cookie, named after its state, so that requests started in parallel (e.g. several
  # tabs restored at once) do not overwrite each other's state
  def oauth_request_state_cookie(state)
    "#{OAUTH_REQUEST_STATE_COOKIE}_#{Digest::SHA256.hexdigest(state.to_s)[0, 16]}"
  end

  def oauth_request_state
    return {} if params[:state].blank?

    cookies.encrypted[oauth_request_state_cookie(params[:state])] || {}
  end

  def store_oauth_request_state(state)
    cookies.encrypted[oauth_request_state_cookie(state[:csrf_token])] = {
      value: state,
      # Abandoned requests expire instead of accumulating
      expires: 10.minutes.from_now,
      path: RedmineApp::Application.config.relative_url_root || '/',
      same_site: :lax,
      secure: Setting.protocol == 'https',
      httponly: true
    }
  end

  def clear_oauth_request_state(state = params[:state])
    return if state.blank?

    cookies.delete oauth_request_state_cookie(state),
                   path: RedmineApp::Application.config.relative_url_root || '/'
  end

  # Exchange the authorization code for a token and get the user's data from the provider
  def fetch_user_info(oauth_provider, code_verifier)
    case oauth_provider.oauth_name
    when 'Azure AD'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      id_token = JWT.decode(token.params['id_token'], nil, false).first
      RedmineOauthController.validate_audience id_token['aud'], oauth_provider
      user_info = id_token.flatten_data
      email = user_info['email']
    when 'GitHub'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get('https://api.github.com/user', headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body).flatten_data
      email = user_info['email']
    when 'GitLab'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get('/api/v4/user', headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body).flatten_data
      user_info['login'] = user_info['username']
      email = user_info['email']
    when 'Google'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      userinfo_response = token.get('https://openidconnect.googleapis.com/v1/userinfo',
                                    headers: { 'Accept' => 'application/json' })
      user_info = JSON.parse(userinfo_response.body).flatten_data
      user_info['login'] = user_info['email']
      RedmineOauthController.validate_hosted_domain user_info, oauth_provider

      email = user_info['email']
    when 'Keycloak'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      access_token = JWT.decode(token.token, nil, false).first
      RedmineOauthController.validate_audience access_token['azp'], oauth_provider
      user_info = access_token.flatten_data
      # Preserve malformed claims so the managed login policy cannot treat them as missing.
      if oauth_provider.email_verification_policy == 'allow_managed_login'
        user_info.merge! access_token.slice('email_verified', 'preferred_username')
      end
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
      user_info = JSON.parse(userinfo_response.body).flatten_data
      user_info['login'] = user_info['preferred_username']
      email = user_info['email']
      session[:oauth_id_token] = token.params[:id_token]
    when 'Custom'
      token = RedmineOauth::OauthClient.client(oauth_provider).auth_code.get_token(params['code'],
                                                                                   redirect_uri: oauth_callback_url,
                                                                                   code_verifier: code_verifier)
      if oauth_provider.custom_profile_endpoint.empty?
        user_info = JWT.decode(token.token, nil, false).first.flatten_data
      else
        userinfo_response = token.get(
          oauth_provider.custom_profile_endpoint,
          headers: { 'Accept' => 'application/json' }
        )
        user_info = JSON.parse(userinfo_response.body).flatten_data
      end
      user_info['login'] = user_info[oauth_provider.custom_uid_field]
      email = user_info[oauth_provider.custom_email_field]
    else
      raise StandardError, l(:oauth_invalid_provider)
    end
    [email, user_info]
  end
end
