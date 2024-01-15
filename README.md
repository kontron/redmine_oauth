## Redmine OAuth plugin 2.1.5

[![GitHub CI](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml/badge.svg?branch=main)](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml)
[![Support Ukraine Badge](https://bit.ly/support-ukraine-now)](https://github.com/support-ukraine/support-ukraine)

This plugin is used to authenticate in Redmine through an OAuth provider.

The user is identified by the email registered by the OAuth provider. The email must correspond with an email registered 
in Redmine. If such an email is not found, the user is ofered with registration to Redmine depending on the Redmine's 
setting **Self-registration**.

Inspired by Gucin's plugin https://github.com/Gucin/redmine_omniauth_azure.

Supported OAuth providers:
* Azure AD (https://azure.microsoft.com)
* GitLab (https://about.gitlab.com)
* Google (https://google.com)
* Keycloak (https://www.keycloak.org)
* Otka (https://www.okta.com)

### Installation:

1. Enter the plugins folder 
2. Clone the repository
3. Set user permissions
4. Install required gems
5. Restart the application

E.g. Linux + Apache web server

```shell 
cd plugins
git clone https://github.com/kontron/redmine_oauth.git
chown -R www-data:www-data redmine_oauth
cd ..
bundle install
systemctl restart apache2
```

### Registration

Register your Redmine instance as an application by your OAuth provider. Follow the instructions given on their web 
sites. As the redirect URI add https://yourdomain/oauth2callback.

### Configuration

Open _Administration -> Plugins_ in your Redmine and configure the plugin.

 E.g.:

**Provider**  Azure AD

**Site**  https://login.microsoftonline.com

**Client ID** xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

**Client secret** xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

**Tenant ID / Realm** xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxxxxxx

---
**Provider**  Google

**Site**  https://accounts.google.com

**Client ID** xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

**Client secret** xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

### Tasks

## Receive IMAP
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

```rake redmine_oauth:email:receive_imap username='notifications@example.com' RAILS_ENV="production"```

**Prior accessing IMAP via OAuth, it is necessary to grant flow to authenticate IMAP connections.**

Here is a procedure how to do that in Azure:

https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#use-client-credentials-grant-flow-to-authenticate-imap-and-pop-connections

### Uninstallation

```
cd plugins
rm redmine_oauth
```
Then restart the application/web server.