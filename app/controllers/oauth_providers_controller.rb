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
    oauth_provider.update_from_parameters params[:oauth_provider]
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
    @oauth_provider.update_from_parameters params[:oauth_provider]
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
end
