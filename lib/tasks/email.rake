# encoding: utf-8
# frozen_string_literal: true
#
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

namespace :redmine_oauth do
  namespace :email do

desc <<-END_DESC
  Read emails from an IMAP server.
END_DESC

    task receive_imap: :environment do
      imap_options = {
        host: ENV['host'],
        port: ENV['port'],
        ssl: ENV['ssl'],
        starttls: ENV['starttls'],
        username: ENV['username'],
        password: ENV['access_token'],
        folder: ENV['folder'],
        move_on_success: ENV['move_on_success'],
        move_on_failure: ENV['move_on_failure']
      }
      Mailer.with_synched_deliveries do
        Redmine::IMAP.check imap_options, MailHandler.extract_options_from_env(ENV)
      end
    end

  end
end
