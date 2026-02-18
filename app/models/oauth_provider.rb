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

# OauthProvider model class
class OauthProvider < ApplicationRecord
  validates :oauth_name, presence: true
  validates :site, format: { without: /\.ru\b/ }, length: { maximum: 40 }
  validates :client_id, presence: true, length: { maximum: 80 }
  validates :client_secret, presence: true, length: { maximum: 128 } # Must be longer due to an optional cyphering
  validates :tenant_id, length: { maximum: 40 }
  validates :custom_name, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :custom_auth_endpoint, length: { maximum: 80 }
  validates :custom_auth_endpoint, presence: true, if: proc { |p| p.custom_name == 'Custom' }
  validates :custom_token_endpoint, length: { maximum: 80 }
  validates :custom_token_endpoint, presence: true, if: proc { |p| p.custom_name == 'Custom' }
  validates :custom_profile_endpoint, length: { maximum: 80 }
  validates :custom_scope, length: { maximum: 40 }
  validates :custom_uid_field, length: { maximum: 40 }
  validates :custom_email_field, length: { maximum: 40 }
  validates :custom_firstname_field, length: { maximum: 30 }
  validates :custom_lastname_field, length: { maximum: 30 }
  validates :custom_logout_endpoint, length: { maximum: 80 }
  validates :validate_user_roles, length: { maximum: 40 }
  validates :url_parameters, length: { maximum: 128 }
  validates :button_text, length: { maximum: 24 }

  scope :sorted, -> { order(:position) }

  def update_from_parameters(params)
    self.oauth_name = params['oauth_name']
    self.site = params['site']
    self.client_id = params['client_id']
    self.client_secret = Redmine::Ciphering.encrypt_text(params['client_secret'])
    self.tenant_id = params['tenant_id']
    self.custom_name = params['custom_name']
    self.custom_auth_endpoint = params['custom_auth_endpoint']
    self.custom_token_endpoint = params['custom_token_endpoint']
    self.custom_profile_endpoint = params['custom_profile_endpoint']
    self.custom_scope = params['custom_scope']
    self.custom_uid_field = params['custom_uid_field']
    self.custom_email_field = params['custom_email_field']
    self.button_color = params['button_color']
    self.button_icon = params['button_icon']
    self.custom_firstname_field = params['custom_firstname_field']
    self.custom_lastname_field = params['custom_lastname_field']
    self.custom_logout_endpoint = params['custom_logout_endpoint']
    self.validate_user_roles = params['validate_user_roles']
    self.enable_group_roles = params['enable_group_roles']
    self.oauth_version = params['oauth_version']
    self.identify_user_by = params['identify_user_by']
    self.imap = params['imap']
    self.url_parameters = params['url_parameters']
    self.button_text = params['button_text']
    # Reset IMAP by other providers
    OauthProvider.where.not(id: id).where(imap: true).update(imap: false) if imap
  end
end
