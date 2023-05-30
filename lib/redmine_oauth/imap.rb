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

require 'net/imap'

module RedmineOauth
  # IMAP
  module IMAP
    class << self
      def check(imap_options = {}, options = {})
        host = imap_options[:host] || 'outlook.office365.com'
        port = imap_options[:port] || '993'
        scope = imap_options[:scope] || 'https://outlook.office365.com/.default'
        grant_type = imap_options[:grant_type] || 'client_credentials'
        ssl = imap_options[:ssl].present? || true
        starttls = !imap_options[:starttls].nil?
        folder = imap_options[:folder] || 'INBOX'
        client = OAuth2::Client.new(
          Setting.plugin_redmine_oauth[:client_id],
          Setting.plugin_redmine_oauth[:client_secret],
          site: Setting.plugin_redmine_oauth[:site]&.chomp('/'),
          token_url: "/#{Setting.plugin_redmine_oauth[:tenant_id]}/oauth2/v2.0/token"
        )
        params = {
          scope: scope,
          grant_type: grant_type
        }
        access_token = client.get_token(params)
        imap = Net::IMAP.new(host, port, ssl)
        imap.starttls if starttls
        imap.authenticate('XOAUTH2', imap_options[:username], access_token.token)
        imap.select folder
        imap.uid_search(%w[NOT SEEN]).each do |uid|
          msg = imap.uid_fetch(uid, 'RFC822')[0].attr['RFC822']
          Rails.logger.debug { "Receiving message #{uid}" }
          if MailHandler.safe_receive(msg, options)
            Rails.logger.debug { "Message #{uid} successfully received" }
            imap.uid_copy(uid, imap_options[:move_on_success]) if imap_options[:move_on_success]
            imap.uid_store uid, '+FLAGS', %i[Seen Deleted]
          else
            Rails.logger.debug { "Message #{uid} can not be processed" }
            imap.uid_store uid, '+FLAGS', %i[Seen]
            if imap_options[:move_on_failure]
              imap.uid_copy uid, imap_options[:move_on_failure]
              imap.uid_store uid, '+FLAGS', [:Deleted]
            end
          end
        end
        imap.expunge
        imap.logout
        imap.disconnect
      end
    end
  end
end
