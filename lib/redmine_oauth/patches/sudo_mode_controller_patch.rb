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

module RedmineOauth
  module Patches
    # SudoModeController patch
    module SudoModeControllerPatch
      def require_sudo_mode(*param_names)
        # Skip the sudo mode during an AJAX call
        return true if request.xhr?

        return true if Redmine::SudoMode.active?

        if session.delete(:oauth_sudo_mode_ok)
          Rails.logger.info "Activating sudo mode for #{User.current.login}"
          Redmine::SudoMode.active!
        end

        return true if Redmine::SudoMode.active?

        param_names = params.keys - %w[id action controller authenticity_token utf8] if param_names.blank?
        back_url = url_for(**params.slice(:controller, :action, :id, :project_id).to_unsafe_hash)

        session[:oauth_sudo_mode] = {
          back_url: back_url,
          params: params.slice(*param_names, '_method').to_unsafe_hash,
          options: {
            method: request.method_symbol,
            authenticity_token: :auto
          }
        }

        oauth_provider_id = OauthProvider.where(id: session[:oauth_login]).pick(:id)
        return super unless oauth_provider_id

        Rails.logger.info "Reauthenticating #{User.current.login} for sudo mode"
        redirect_to oauth_path(back_url: back_url, oauth_provider: oauth_provider_id, reauth: true)
      end
    end
  end
end

Redmine::SudoMode::Controller.prepend RedmineOauth::Patches::SudoModeControllerPatch
