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

module RedmineOauth
  module Patches
    # SettingsController patch
    module SettingsControllerPatch
      def self.prepended(base)
        base.class_eval do
          before_action :cipher_settings, only: [:plugin], prepend: true
        end
      end

      def cipher_settings
        return unless request.post? && (params[:id] == 'redmine_oauth')

        params[:settings][:client_secret] = Redmine::Ciphering.encrypt_text(params[:settings][:client_secret])
      end
    end
  end
end

# Apply the patch
SettingsController.prepend RedmineOauth::Patches::SettingsControllerPatch
