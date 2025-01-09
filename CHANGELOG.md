Changelog for Redmine OAuth
==========================

3.0.2 *2025-01-09*
------------------

    PKCE (Proof Key for Code Exchange) support 

* New: #69 - Add PKCE support to redmine_oauth_controller

3.0.1 *2024-12-06*
------------------

* Bug: #64 - Adds custom_uid_field and custom_email_field to RedmineOauth class

3.0.0 *2024-12-06*
------------------

    Redmine 6

* Bug: #62 - Keycloak logout url fix
* Bug: #61 - OAuth logout
* New: #60 - Redmine 6 
* New: #59 - Issue with authentication against MS Entra ID

2.2.8 *2024-10-24*
------------------

    Spanish localization update

* New: #55 - Added more spanish translates

2.2.7 *2024-10-14*
------------------

    Bug fixing 

* Bux: #52 - Self-Registration Behavior with Google Login 


2.2.6 *2024-10-10*
------------------

    Spanish localization fix

* Bug: #51 - Text is spanish by default

2.2.5 *2024-10-09*
------------------

    Spanish localization
    An automatic update of user's name based on data from OAuth
    Authorization based on roles provided from OAuth
    Automatic logon
    SSO Logoff

* New: #50 - Added file with language spanish (Spain) "es_ES"
* New: #43 - Setting username automatically
* New: #36 - Require a certain role or group membership to allow login
* New: #32 - Option to skip manual button press requirement if redmine_oauth only authentication method

2.2.4 *2024-07-23*
------------------

    Bugs fixing

* Bug: #46 - IMAP: Invalid client secret provided 

2.2.3 *2024-07-18*
------------------

    Client secret encrypted
    Configurable provider's fields for the first and last name

* New: #45 - Add configuration fields for mapping of first name and last name values
* New: #44 - Encrypt client_secret

2.2.2 *2024-07-04*
------------------

    Separated self-registartion

* New: #42 - Add standalone self-registration setting
* New: #41 - Update README.md
* New: #39 - Decouple self-registration and OIDC registration 

2.2.1 *2024-06-04*
------------------

    An option to hide the login form
    Do not require a password change or 2FA initialization if OAuth is being used

* New: #31 - Enhance Keycloak documentation
* New: #30 - Incentive to use this plugin (tighten password rules / co-usage of oauth2 login)
* New: #28 - Is it possible to hide the normal login/password prompt through config when a instance just needs OAuth login

2.2.0 *2024-03-05*
------------------

    Custom OIDC provider

* New: #24 - Custom OIDC provider

2.1.5 *2024-01-15*
------------------

    French localisation

* New: #23 - [Locales] Add french translation 

2.1.4 *2024-01-12*
------------------
    
    Autologin
    Google OAuth provider
    Keycloak OAuth provider

* New: #22 - About feature requests and providers enhancement
* New: #21 - Autologin enhancement

2.1.3 *2023-11-20*
------------------

    IMAP authentication fix

* Bug: #20 - connection closed

2.1.2 *2023-11-15*
------------------

    Redmine 5.1.x required (no more conflict with net-imap gem)

2.1.1 *2023-06-02*
------------------

    GitLab enhancement

2.1.0 *2023-06-02*
------------------

    GitLab OAuth provider

* New: #12 - Add support for GitLab OAuth provider

2.0.2 *2023-02-10*
------------------

    Back URL

* Bug: #8 - back_url bug

2.0.1 *2022-12-23*
------------------

    Invalid credentials error

2.0.0 *2022-11-08*
------------------

    Receive IMAP over OAuth rake task

1.0.4 *2022-10-26*
------------------

    Users' last connection timestamp

1.0.3 *2022-10-18*
------------------

    Right processing of locked users

1.0.2 *2022-10-10*
------------------

    German localisation

1.0.1 *2022-10-07*
------------------

    Okta OAuth provider
    Cross Site Request Forgery implementation
    OAuth login button facelift

1.0.0 *2022-09-16*
------------------

    Azure AD OAuth provider
