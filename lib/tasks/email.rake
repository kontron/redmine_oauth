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

namespace :redmine_oauth do
  namespace :email do
    desc <<-END_DESC
      Read emails from an IMAP server and process them into Redmine.

      Available options:
        * host - IMAP server ['outlook.office365.com']
        * port - Port [993]
        * scope - Scope ['https://outlook.office365.com/.default']
        * grant_type - Grant type ['client_credentials']
        * ssl - use SSL [Yes]
        * starttls - Start TLS [No]
        * username - Login
        * folder - Mail folder to scan ['INBOX']
        * move_on_success - Where to move successfully processed messages
        * move_on_failure - Where to move unsuccessfully processed messages

      Example:
        rake redmine_oauth:email:receive_imap username='notifications@example.com' RAILS_ENV="production"
    END_DESC

    task receive_imap: :environment do
      imap_options = {
        host: ENV.fetch('host', 'outlook.office365.com'),
        port: ENV.fetch('port', '993'),
        scope: ENV.fetch('scope', 'https://outlook.office365.com/.default'),
        grant_type: ENV.fetch('grant_type', 'client_credentials'),
        ssl: ENV.fetch('ssl', true),
        starttls: ENV.fetch('starttls', false),
        username: ENV.fetch('username', ''),
        folder: ENV.fetch('folder', 'INBOX'),
        move_on_success: ENV.fetch('move_on_success', nil),
        move_on_failure: ENV.fetch('move_on_failure', nil)
      }
      Mailer.with_synched_deliveries do
        RedmineOauth::IMAP.check imap_options, MailHandler.extract_options_from_env(ENV)
      rescue StandardError => e
        warn e.message
      end
    end
  end
end
