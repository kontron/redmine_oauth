## Redmine OAuth plugin 3.0.2

[![GitHub CI](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml/badge.svg?branch=main)](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml)
[![Support Ukraine Badge](https://bit.ly/support-ukraine-now)](https://github.com/support-ukraine/support-ukraine)

This plugin is used to authenticate in Redmine through an OAuth provider.

The user is identified by the email registered with the OAuth provider. The email must match an email registered
in Redmine. If such an email is not found, the user will be offered to register in Redmine, depending on Redmine's 
setting **Self-registration**. OAuth logout is also supported, if it is set in the options.
Access to Redmine can be controlled by roles assigned in your OAuth provider.
See [#36](https://github.com/kontron/redmine_oauth/issues/36#issuecomment-2348842432) for details; as well as OAuth 
autologin.

Inspired by Gucin's plugin https://github.com/Gucin/redmine_omniauth_azure.

Supported OAuth providers:
* Azure AD (https://azure.microsoft.com)
* Custom (OpenID Connect - OIDC)
* GitLab (https://about.gitlab.com)
* Google (https://google.com)
* Keycloak (https://www.keycloak.org)
* Okta (https://www.okta.com)

### Installation:

1. Enter the plugins folder 
2. Clone the repository
3. Set user permissions
4. Install required gems
5. Restart the application

e.g. Linux + Apache web server

```shell 
cd plugins
git clone https://github.com/kontron/redmine_oauth.git
chown -R www-data:www-data redmine_oauth
cd ..
bundle install
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

Open _Administration -> Plugins_ in your Redmine and configure the plugin.

Examples:

#### Provider Azure AD

* Site: https://login.microsoftonline.com
* Client ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
* Client secret: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
* Tenant ID / Realm `xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxxxxxx`

#### Provider Google

* Site: https://accounts.google.com
* Client ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
* Client secret: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

#### Provider Keycloak

Create a new OIDC Client in your Keycloak Realm. Activate `Client authentication`.

* Site: `https://keycloak.example.com` (without any paths)
* Client-ID: `keycloak.example.com` (do not include `https://` or other special characters in the Client ID)
* Secret: Copy the client secret from Keycloak
* Tenant ID: the name of your Keycloak realm

### Tasks

#### Receive IMAP
Read emails from an IMAP server and process them into Redmine.

Available options:
* host - IMAP server [outlook.office365.com]
* port - Port [993]
* scope - Scope ['https://outlook.office365.com/.default']
* grant_type - Grant type ['client_credentials']
* ssl - use SSL [Yes]
* starttls - Start TLS [No]
* username - Login     
* folder - Mail folder to scan [INBOX]
* move_on_success - Where to move successfully processed messages
* move_on_failure - Where to move unsuccessfully processed messages

Example:

```shell
rake redmine_oauth:email:receive_imap username='notifications@example.com' RAILS_ENV="production"
```

**Prior to accessing IMAP via OAuth, it is necessary to grant flow to authenticate IMAP connections.**

Here is a procedure how to do that in Azure:

https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#use-client-credentials-grant-flow-to-authenticate-imap-and-pop-connections

### Uninstallation

```shell
cd plugins
rm redmine_oauth
```
Then restart the application/web server.
