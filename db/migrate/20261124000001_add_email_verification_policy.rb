# frozen_string_literal: true

# Preserve existing email verification behavior on upgrade.
class AddEmailVerificationPolicy < ActiveRecord::Migration[7.2]
  def up
    add_column :oauth_providers, :email_verification_policy, :string, null: false, default: 'reject_unverified'
    execute <<~SQL.squish
      UPDATE #{quote_table_name('oauth_providers')}
      SET email_verification_policy = 'require_verified'
      WHERE require_verified_email = #{connection.quoted_true}
    SQL
    remove_column :oauth_providers, :require_verified_email
  end

  def down
    add_column :oauth_providers, :require_verified_email, :boolean, null: false, default: false
    execute <<~SQL.squish
      UPDATE #{quote_table_name('oauth_providers')}
      SET require_verified_email = #{connection.quoted_true}
      WHERE email_verification_policy <> 'reject_unverified'
    SQL
    remove_column :oauth_providers, :email_verification_policy
  end
end
