## Redmine OAuth plugin 4.2.4 devel

[![GitHub CI](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml/badge.svg?branch=devel)](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml)
[![Support Ukraine Badge](https://bit.ly/support-ukraine-now)](https://github.com/support-ukraine/support-ukraine)

This plugin is used to authenticate in Redmine through an OAuth provider.

The user is identified by their email, login or immutable user ID (uid) registered with the OAuth provider. The email 
or login must match an email or login registered in Redmine. If such an email or login is not found, the user will be offered to register in 
Redmine, depending on Redmine's setting **Self-registration**. OAuth logout is also supported, if it is set in the 
options. Access to Redmine can be controlled by roles assigned in your OAuth provider.
See [#36](https://github.com/kontron/redmine_oauth/issues/36#issuecomment-2348842432) for details; as well as OAuth autologin.

Inspired by Gucin's plugin https://github.com/Gucin/redmine_omniauth_azure.

Supported OAuth providers:
* Azure AD (https://azure.microsoft.com)
* Custom (OpenID Connect - OIDC)
* GitHub (https://github.com)
* GitLab (https://about.gitlab.com)
* Google (https://google.com)
* Keycloak (https://www.keycloak.org)
* Okta (https://www.okta.com)

### Installation:

1. Enter the plugins folder 
2. Clone the repository
3. Set user permissions
4. Install required gems
5. Migrate the database
6. Restart the application

e.g. Linux + Apache web server

```shell 
cd plugins
git clone https://github.com/kontron/redmine_oauth.git
chown -R www-data:www-data redmine_oauth
cd ..
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_oauth
systemctl restart apache2
```

#### Docker installation

1. Enter the plugins folder you mount into Docker
2. Clone the repository
3. Add permission fix and build-essential:
```
FROM redmine:latest

# Fix permissions for bundle install of bigdecimal for redmine_oauth
RUN chown -R redmine: /usr/local/bundle/ && chmod -R o-w /usr/local/bundle/

# Install build-essential to build dependencies of redmine_oauth
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install --yes --no-install-recommends build-essential \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
```

### Registration

Register your Redmine instance as an application with your OAuth provider. Follow the instructions given on their 
websites. Add `https://yourdomain/oauth2callback` as redirect URI.

### Configuration

Open _Administration -> OAuth providers_ in your Redmine and add your provider(s).

#### Identify user by

* **email** / **login** - The user is matched by their email or login returned by the provider.
* **uid** - The user is matched by the provider's immutable user ID (Azure AD: `oid`; GitHub, GitLab: `id`; others: 
  `sub`), stored in Redmine after the first login. The link survives changes of the user's email or login.
  With **Link existing users by email** (on by default), an existing Redmine user with the same email is linked on 
  their first OAuth login. Turn it off if the provider does not verify email addresses.

**uid** is the recommended choice. Whoever controls the matched value on the provider's side gets access to the 
Redmine account, see below.

#### Security considerations

* **Email** - The plugin trusts the email returned by the provider and does not check any `email_verified` claim. 
  Identify users by email (or link them by email) only if the provider lets users use verified addresses only:
  * Azure AD: the `email` claim can be edited by the user and is not verified, especially for multi-tenant 
    applications (tenant `common` or `organizations`). Use **uid** and a single tenant ID.
  * Keycloak, Okta, Custom: make sure users cannot register or change their email without a verification, or use 
    **uid**.
  * The self-registration mode with automatic activation by email domain relies on the email as well.
* **Login** - Usernames can often be changed by their owners (GitLab `username`, Keycloak/Okta 
  `preferred_username`). A user who renames their account to the login of another Redmine user gets access to 
  that account. Do not identify users by login unless the provider prevents such changes.
* **Roles** - If _Validate user roles_ is set, the `admin` role in the token makes the user a Redmine administrator 
  and its absence revokes the administrator rights on the next login. Groups are synchronized with the other roles. 
  Make sure the key points to a claim managed by the provider's administrators, not by the users. Roles are applied 
  to active accounts only.
* **Hosted domain (Google)** - With `hd=example.com` in _URL parameters_, only accounts of that Google Workspace 
  domain can log in (`hd=*` allows any Workspace domain); personal accounts are rejected.
* **Sudo mode** - If Redmine's sudo mode is enabled, OAuth users re-authenticate with their provider. The provider 
  must return the same user. AJAX requests requiring the sudo mode cannot be redirected to the provider and ask for 
  the Redmine password instead.
* **Client secret** - The secret is stored encrypted (if Redmine's `database_cipher_key` is set) and is not 
  displayed in the provider's form; leave the field blank to keep it.
* **Button text** - Only basic HTML formatting is allowed: `b`, `i`, `u`, `em`, `strong`, `span`, `br` and the 
  `class` attribute.

Examples:

#### Provider Azure AD

* Site: https://login.microsoftonline.com
* Client ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
* Client secret: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
* Tenant ID / Realm `xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxxxxxx`

#### Provider GitHub

* Site: https://github.com
* Client ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
* Client secret: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

#### Provider Google

* Site: https://accounts.google.com
* Client ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
* Client secret: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
* URL parameters (optional): `hd=example.com` to allow only accounts of your Google Workspace domain

#### Provider Keycloak

Create a new OIDC Client in your Keycloak Realm. Activate `Client authentication`.

* Site: `https://keycloak.example.com` (without any paths)
* Client-ID: `keycloak.example.com` (do not include `https://` or other special characters in the Client ID)
* Secret: Copy the client secret from Keycloak
* Tenant ID: the name of your Keycloak realm

### Tasks

#### Receive IMAP
Read emails from an IMAP server and process them into Redmine. Don't forget to set _IMAP_ = **true** by the dedicated 
OAuth provider which provides an access token.

Available options:
* host - IMAP server [outlook.office365.com]
* port - Port [993]
* scope - Scope ['https://outlook.office365.com/.default']
* grant_type - Grant type ['client_credentials']
* ssl - use SSL [true]
* starttls - Start TLS [false]
* username - Login ['']     
* folder - Mail folder to scan [INBOX]
* move_on_success - Where to move successfully processed messages [nil]
* move_on_failure - Where to move unsuccessfully processed messages [nil]

Example:

```shell
rake redmine_oauth:email:receive_imap username='notifications@example.com' RAILS_ENV="production"
```

**Prior to accessing IMAP via OAuth, it is necessary to grant flow to authenticate IMAP connections.**

Here is a procedure how to do that in Azure:

https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#use-client-credentials-grant-flow-to-authenticate-imap-and-pop-connections

### Uninstallation

```shell
bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_oauth VERSION=0
cd plugins
rm -r redmine_oauth
```
Then restart the application/web server.
