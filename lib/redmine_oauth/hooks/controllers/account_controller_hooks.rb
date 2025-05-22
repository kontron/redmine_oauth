# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine OAuth plugin.
#
# Redmine OAuth plugin is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Foobar. If
# not, see <https://www.gnu.org/licenses/>.

module RedmineOauth
  module Hooks
    module Controllers
      # AccountController hooks
      class AccountControllerHooks < Redmine::Hook::Listener
        def controller_account_success_authentication_after(context = {})
          return unless RedmineOauth.oauth_login? && context[:controller].params[:oauth_autologin]

          context[:controller].set_oauth_autologin_cookie
        end
      end
    end
  end
end
