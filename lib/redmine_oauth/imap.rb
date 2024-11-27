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
        client = OAuth2::Client.new(
          RedmineOauth.client_id,
          Redmine::Ciphering.decrypt_text(RedmineOauth.client_secret),
          site: RedmineOauth.site,
          token_url: "/#{RedmineOauth.tenant_id}/oauth2/v2.0/token"
        )
        params = {
          scope: imap_options[:scope],
          grant_type: imap_options[:grant_type]
        }
        access_token = client.get_token(params)
        imap = Net::IMAP.new(imap_options[:host], imap_options[:port], imap_options[:ssl].present?)
        imap.starttls if imap_options[:starttls].present?
        imap.authenticate('XOAUTH2', imap_options[:username], access_token.token)
        imap.select imap_options[:folder]
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
