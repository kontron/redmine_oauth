/*
 Redmine plugin OAuth

 Karel Pičman <karel.picman@kontron.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

function oauth_set_color()
{
    let color = $("input#button_color").val();
    $("#login-oauth-button").css({ backgroundColor: color });
}

function oauth_set_icon()
{
    let icon_class = $("select#settings_button_icon option:selected").val();
    let login_button = $("#login-oauth-button");
    if(icon_class == 'none'){
        login_button.hide();
        return;
    }
    else{
        login_button.show();
    }
    let icon = $("i#button_icon");
    icon.removeClass();
    icon.addClass(icon_class);
}

function oauth_set_btn_title()
{
    let oauth_name = $("input#settings_custom_name").val().trim() ? $("input#settings_custom_name").val().trim() : $("#settings_oauth_name option:selected").val();
    let button = $("button#login-oauth-button");
    let html = button.html();
    html = html.replace(/<b>.*<\/b>/, "<b>" + oauth_name + "</b>");
    button.html(html);
}

function oauth_settings_visibility()
{
    let div_oauth_options = $("div#oauth_options");
    let tenant_id = $("input#settings_tenant_id");   
    let oauth_name = $("#settings_oauth_name option:selected").val();
    $("input#settings_custom_name").val(oauth_name);
    oauth_set_btn_title();
    
    $("input#settings_site").val("");
    $("input#settings_client_id").val("");
    $("input#settings_client_secret").val("");
    
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
            tenant_id.val("");
            break;
        case 'GitLab':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            break;
        case 'Google':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            break;
        case 'Keycloak':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').show();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            tenant_id.val("");
            break;
        case 'Okta':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').show();
            div_oauth_options.find('#oauth_options_tenant').show();
            div_oauth_options.find('#oauth_options_custom').hide();
            div_oauth_options.find('#oauth_option_version').hide();
            tenant_id.val("default");
            break;
        case 'Custom':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_site').hide();
            div_oauth_options.find('#oauth_options_tenant').hide();
            tenant_id.val("");
            div_oauth_options.find('#oauth_option_version').hide();
            div_oauth_options.find('#oauth_options_custom').show();
            $("input#settings_custom_auth_endpoint").val("");
            $("input#settings_custom_token_endpoint").val("");
            $("input#settings_custom_profile_endpoint").val("");
            $("input#settings_custom_scope").val("openid profile email");
            $("input#settings_custom_uid_field").val("preferred_username");
            $("input#settings_custom_email_field").val("email");
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

function oauth_self_registration_changed()
{
    let osr = $("#oauth_self_registration");
    let sr = $("#settings_self_registration");
    if (sr.val() > 0) {
        osr.show();
    }
    else {
        osr.hide();
    }
}
