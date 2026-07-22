# frozen_string_literal: true

# Redmine plugin OAuth
#
# The input fields for "Scope" enforce a maximum length of 40 characters.
# This is insufficient for real-world IdP endpoints.

# OauthProviders DB migration
class OauthProviderCustomScopeLength < ActiveRecord::Migration[7.2]
  def up
    change_column :oauth_providers, :custom_scope, :string, null: true, limit: 256
  end
end
