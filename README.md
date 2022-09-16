## Redmine OAuth plugin

![GitHub Action](https://github.com/kontron/redmine_oauth/actions/workflows/rubyonrails.yml/badge.svg?branch=master)
[![Support Ukraine Badge](https://bit.ly/support-ukraine-now)](https://github.com/support-ukraine/support-ukraine)

This plugin is used to authenticate in Redmine through OAuth.
Inspired by Gucin's plugin https://github.com/Gucin/redmine_omniauth_azure.

Supported OAuth providers:
* Azure AD

### Installation:

Choose folder /plugins, make command

```
cd plugins
git clone https://github.com/kontron/redmine_oauth.git
bundle install
```
Then restart the application/web server.

### Registration

Register your Redmine instance as an application by your OAuth provider. Follow the instructions given on their web 
sites.

### Configuration

Open Administration -> Plugins in your Redmine and configure the plugin. All the listed settings are mandatory.

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