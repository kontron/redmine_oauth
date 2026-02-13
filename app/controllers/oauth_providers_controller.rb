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

# OauthProviders controller class
class OauthProvidersController < ApplicationController
  layout 'admin'

  model_object OauthProvider
  menu_item :oauth_provides
  self.main_menu = false

  helper :sort
  include SortHelper

  before_action :require_admin
  before_action :find_model_object, except: %i[create new index]

  def index
    @oauth_providers = OauthProvider.sorted.all
  end

  def new
    @oauth_provider = OauthProvider.new
  end

  def create
    oauth_provider = OauthProvider.new
    update_from_parameters oauth_provider, params[:oauth_provider]
    oauth_provider.position = OauthProvider.all.size + 1 if oauth_provider
    if request.post? && oauth_provider.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to oauth_providers_path
    else
      @oauth_provider = oauth_provider
      render action: 'new'
    end
  end

  def update
    update_from_parameters @oauth_provider, params[:oauth_provider]
    if request.patch? && @oauth_provider.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to oauth_providers_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @oauth_provider.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to oauth_providers_path
  end

  private

  def update_from_parameters(provider, params)
    provider.oauth_name = params['oauth_name']
    provider.site = params['site']
    provider.client_id = params['client_id']
    provider.client_secret = Redmine::Ciphering.encrypt_text(params['client_secret'])
    provider.tenant_id = params['tenant_id']
    provider.custom_name = params['custom_name']
    provider.custom_auth_endpoint = params['custom_auth_endpoint']
    provider.custom_token_endpoint = params['custom_token_endpoint']
    provider.custom_profile_endpoint = params['custom_profile_endpoint']
    provider.custom_scope = params['custom_scope']
    provider.custom_uid_field = params['custom_uid_field']
    provider.custom_email_field = params['custom_email_field']
    provider.button_color = params['button_color']
    provider.button_icon = params['button_icon']
    provider.custom_firstname_field = params['custom_firstname_field']
    provider.custom_lastname_field = params['custom_lastname_field']
    provider.custom_logout_endpoint = params['custom_logout_endpoint']
    provider.validate_user_roles = params['validate_user_roles']
    provider.oauth_version = params['oauth_version']
    provider.identify_user_by = params['identify_user_by']
    provider.imap = params['imap']
    # Reset IMAP by other providers
    OauthProvider.where.not(id: provider.id).where(imap: true).update(imap: false) if provider.imap
  end
end
