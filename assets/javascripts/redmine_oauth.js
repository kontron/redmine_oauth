/*
 Redmine plugin OAuth

 Karel Pičman <karel.picman@kontron.com>

 This file is part of Redmine OAuth plugin.

 Redmine OAuth plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
 Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
 later version.

 Redmine OAuth plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 more details.

 You should have received a copy of the GNU General Public License along with Redmine OAuth plugin. If not, see
 <https://www.gnu.org/licenses/>.
*/

function oauth_set_color()
{
    let color = $("input#oauth_provider_button_color").val();
    $("#login-oauth-button").css({ backgroundColor: color });
}

function oauth_set_icon()
{
    let icon_class = $("select#oauth_provider_button_icon option:selected").val();
    let icon = $("i#button_icon");
    icon.removeClass();
    icon.addClass(icon_class);
}

function oauth_set_button_text()
{
    let alternative_text = $("input#oauth_provider_button_text");
    if(alternative_text.val().trim()) {
        // We have an alternative text => Do not set anything
        return;
    }
    let oauth_name = $("input#oauth_provider_custom_name").val().trim() ? $("input#oauth_provider_custom_name").val().trim() : $("#oauth_provider_oauth_name option:selected").val();
    let button = $("button#login-oauth-button");
    let html = button.html();
    html = html.replace(/<\/i>\s.*$/, "</i>\n<b>" + oauth_name + "</b>");
    button.html(html);
}

function oauth_set_alternative_button_text(val) {
    if(!val.trim()) {
        val = $("input#oauth_provider_custom_name").val().trim() ? $("input#oauth_provider_custom_name").val().trim() : $("#oauth_provider_oauth_name option:selected").val();
    }
    let button = $("button#login-oauth-button");
    let icon = $("select#oauth_provider_button_icon option:selected");
    button.html("<i id=\"button_icon\" class=\"" + icon.text() + "\"></i>\n" + val);
}

function oauth_settings_visibility() {
    let div_oauth_options = $("div#oauth_options");
    let tenant_id = $("input#oauth_provider_tenant_id");
    let oauth_name = $("#oauth_provider_oauth_name option:selected").val();
    let site = $("input#oauth_provider_site");

    $("input#oauth_provider_custom_name").val(oauth_name);
    oauth_set_button_text();
    
    site.val("");
    $("input#oauth_provider_client_id").val("");
    $("input#oauth_provider_client_secret").val("");
    
    switch(oauth_name) {
        case 'none':
            div_oauth_options.hide();
            tenant_id.val("");
            break;
        case 'Azure AD':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').show();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').show();
            div_oauth_options.find('#oauth_google_options').hide();
            tenant_id.val("");
            site.val("https://login.microsoftonline.com");
            break;
        case 'GitHub':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            div_oauth_options.find('#oauth_google_options').hide();
            site.val("https://github.com");
            break;
        case 'GitLab':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            div_oauth_options.find('#oauth_google_options').hide();
            break;
        case 'Google':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_google_options').show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            site.val("https://accounts.google.com");
            break;
        case 'Keycloak':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').show();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            div_oauth_options.find('#oauth_google_options').hide();
            tenant_id.val("");
            break;
        case 'Okta':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').show();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            div_oauth_options.find('#oauth_google_options').hide();
            tenant_id.val("default");
            break;
        case 'Custom':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_custom').show();
            div_oauth_options.find('#oauth_options_site').hide();
            div_oauth_options.find('#oauth_options_tenant').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            div_oauth_options.find('#oauth_google_options').hide();
            tenant_id.val("");
            $("input#oauth_provider_custom_auth_endpoint").val("");
            $("input#oauth_provider_custom_token_endpoint").val("");
            $("input#oauth_provider_custom_profile_endpoint").val("");
            $("input#oauth_provider_custom_scope").val("openid profile email");
            $("input#oauth_provider_custom_uid_field").val("preferred_username");
            $("input#oauth_provider_custom_email_field").val("email");
            break;    
        default:
            break;
    }
}

function oauth_toggle_fieldset(el)
{
    let fieldset = el.parentNode;
    fieldset.classList.toggle('oauth_expanded');
    fieldset.classList.toggle('oauth_collapsed');
    $('div#login-form').toggle();
}