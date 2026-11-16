# SSO-only authentication for OAuth users

This change targets kontron/redmine_oauth **v4.2.3**, commit
`e2f24aa4a984688fb48e8e13c36497845a4e2342` (Redmine >= 6.0). It does not
modify Redmine core or require a database schema migration. The `AuthSourceOauth`
source is created on first use in Redmine's existing `auth_sources` table.

## Configuration and behavior

Enable **Disable local passwords for OAuth users** in Administration > Plugins >
Redmine OAuth > Configure.

- Existing non-administrator accounts are converted on their next successful
  OAuth login, before the session is established.
- New accounts registered through OAuth are assigned the SSO source immediately.
- Existing administrator accounts are excluded from automatic conversion. An
  administrator can be converted explicitly with the task below.
- Converted accounts cannot sign in with a local password, change one, or request
  a password reset.
- Conversion clears the local password hash and salt and deletes recovery,
  autologin, and session tokens, ending existing sessions. Later OAuth logins do
  not revoke sessions again.
- API and feed tokens are retained.
- Assigning the SSO source manually in a user's administration form also clears
  the local password and relevant tokens on save.

Disabling the setting prevents future automatic conversions; it does not restore
local passwords or change the authentication source for accounts already converted.

## Migrating existing accounts

The plugin does not keep a reliable history of which accounts have used OAuth.
The task therefore takes an explicit list of logins and does not guess which
accounts to convert. From the Redmine root, preview the changes first:

```sh
RAILS_ENV=production LOGINS=alice,bob bundle exec rake redmine_oauth:migrate_sso
```

To apply the conversion:

```sh
RAILS_ENV=production LOGINS=alice,bob APPLY=1 bundle exec rake redmine_oauth:migrate_sso
```

A missing login aborts the task before any conversion. All selected accounts are
converted in a single transaction. The task works independently of the automatic
conversion setting.

Administrator accounts require `INCLUDE_ADMINS=1`. Keep at least one local
administrator account independent of Keycloak and leave it out of the migration.

## Recovery and rollback

Existing recovery tokens are deleted during conversion. The controller also
rejects GET and POST recovery requests for SSO accounts, including requests using
a token already stored in the session.

To return an account to local authentication, an administrator can change its
authentication source and set a new password. Before removing this code, move all
SSO accounts to another installed authentication source and remove the unused
OAuth SSO source. Otherwise Redmine cannot load the `AuthSourceOauth` STI type
stored in the database.

## Testing

The focused test harness used Ruby 3.2.3, ActiveRecord 7.2.3.2, and SQLite. It
passed 13 tests and 38 assertions covering conversion, OAuth registration, the
disabled setting, administrator exclusion, password clearing, token revocation,
session retention on subsequent logins, recovery protection, transaction rollback,
and reuse of the SSO source after renaming.

These tests run the changed code against a real database with a minimal
application harness. They do not boot Redmine or exercise an OIDC exchange with
Keycloak. Ruby syntax, YAML parsing, and patch application against v4.2.3 were
also checked.

The Redmine integration tests are in `test/functional/oauth_sso_test.rb`. Run
them against a configured test database, never the production database:

```sh
RAILS_ENV=test bundle exec rake redmine:plugins:test:functionals NAME=redmine_oauth
```

Before enabling this for all users, verify OAuth sign-in, rejection of the old
local password, blocked password changes and recovery, invalidation of an old
recovery link, and sign-in to the independent local administrator account.
