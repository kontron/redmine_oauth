# frozen_string_literal: true

# Redmine plugin OAuth
#
# Since the HTML color input field does not allow to set "null" values:
# adding a boolean field to allow users to disable the coloration
# To be backwards compatible, it defaults to true

# OauthProviders DB migration
class AddButtonColorEnabledToOauthProviders < ActiveRecord::Migration[7.2]
  def change
    add_column :oauth_providers, :button_color_enabled, :boolean, null: false, default: true
  end
end
