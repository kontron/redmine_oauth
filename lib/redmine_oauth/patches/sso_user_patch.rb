# frozen_string_literal: true

module RedmineOauth
  module Patches
    module SsoUserPatch
      def self.prepended(base)
        base.before_save :clear_oauth_local_credentials
        base.after_save :revoke_oauth_password_tokens
      end

      private

      def clear_oauth_local_credentials
        return unless auth_source.is_a?(AuthSourceOauth)

        self.hashed_password = ''
        self.salt = ''
        self.password = self.password_confirmation = nil
        self.must_change_passwd = false
        self.generate_password = false
      end

      def revoke_oauth_password_tokens
        return unless auth_source.is_a?(AuthSourceOauth)

        Token.where(user_id: id, action: 'recovery').delete_all
        if saved_change_to_auth_source_id?
          Token.where(user_id: id, action: %w[autologin session]).delete_all
        end
      end
    end
  end
end

Rails.application.config.to_prepare do
  User.prepend RedmineOauth::Patches::SsoUserPatch unless User < RedmineOauth::Patches::SsoUserPatch
end
