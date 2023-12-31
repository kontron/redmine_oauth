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

function oauth_settings_visibility()
{
    let div_oauth_options = $("div#oauth_options");
    let tenant_id = $("input#settings_tenant_id");
    let button = $("button#login-oauth-button");
    let oauth_name = $("#settings_oauth_name option:selected").val();
    let html = button.html();
    $("input#settings_site").val("");
    $("input#settings_client_id").val("");
    $("input#settings_client_secret").val("");
    html = html.replace(/<b>.*<\/b>/, "<b>" + oauth_name + "</b>");
    button.html(html);
    switch(oauth_name) {
        case 'none':
            div_oauth_options.hide();
            tenant_id.val("");
            break;
        case 'Azure AD':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_tenant').show();
            tenant_id.val("");
            break;
        case 'GitLab':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            break;
        case 'Google':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_tenant').hide();
            break;
        case 'Keycloak':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_tenant').show();
            tenant_id.val("");
            break;
        case 'Okta':
            div_oauth_options.show();
            div_oauth_options.find('#oauth_options_tenant').show();
            tenant_id.val("default");
            break;
        default:
            break;
    }
}