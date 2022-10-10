## Redmine OAuth plugin 1.0.3 devel

[![GitHub CI](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml/badge.svg?branch=devel)](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml)
[![Support Ukraine Badge](https://bit.ly/support-ukraine-now)](https://github.com/support-ukraine/support-ukraine)

This plugin is used to authenticate in Redmine through OAuth.
Inspired by Gucin's plugin https://github.com/Gucin/redmine_omniauth_azure.

Supported OAuth providers:
* Azure AD (https://azure.microsoft.com)
* Otka (https://www.okta.com/)

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

**Tenant ID** xxxxxxxx-xxx-xxxx-xxxx-xxxxxxxxxxxx

### Uninstalation

```
cd plugins
rm redmine_oauth
```
Then restart the application/web server.