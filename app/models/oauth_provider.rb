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
  validates :site, presence: true, format: { without: /\.ru\b/ }, length: { maximum: 40 }
  validates :client_id, presence: true, length: { maximum: 60 }
  validates :client_secret, presence: true, length: { maximum: 128 }
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

  scope :sorted, -> { order(:position) }
end
