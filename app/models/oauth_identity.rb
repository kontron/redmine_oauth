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

# OauthIdentity model class
# Links a Redmine user to the immutable user ID (e.g. Azure 'oid', OIDC 'sub') issued by an OAuth provider
class OauthIdentity < ApplicationRecord
  belongs_to :oauth_provider
  belongs_to :user

  validates :uid, presence: true, length: { maximum: 255 }
  validates :uid, uniqueness: { scope: :oauth_provider_id }
  validates :user_id, uniqueness: { scope: :oauth_provider_id }
end
