# frozen_string_literal: true

# Redmine plugin OAuth
#
# Widen client_id: Google and other providers use IDs longer than varchar(60).

class OauthProviderClientIdLength < ActiveRecord::Migration[7.2]
  def up
    change_column :oauth_providers, :client_id, :string, null: false, limit: 255
  end

  def down
    change_column :oauth_providers, :client_id, :string, null: false, limit: 60
  end
end
