# frozen_string_literal: true

# Redmine plugin OAuth
#
# Widen client_id: Google and other providers use IDs longer than varchar(60).
# Widen site as well to keep both URL-related fields consistent.

# OauthProviders DB migration
class OauthProviderClientIdLength < ActiveRecord::Migration[7.2]
  def up
    change_column :oauth_providers, :site, :string, null: true, limit: 256
    change_column :oauth_providers, :client_id, :string, null: false, limit: 256
  end

  def down
    change_column :oauth_providers, :site, :string, null: true, limit: 40
    change_column :oauth_providers, :client_id, :string, null: false, limit: 80
  end
end
