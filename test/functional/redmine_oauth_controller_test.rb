# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine OAuth plugin.
#
# Redmine OAuth plugin is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Foobar. If
# not, see <https://www.gnu.org/licenses/>.

# Load the normal Rails helper
require File.expand_path('../../../../../test/test_helper', __FILE__)

# OAuth controller
class RedmineOauthControllerTest < ActionDispatch::IntegrationTest
  include Redmine::I18n

  fixtures :users

  def test_oauth
    Setting.plugin_redmine_oauth[:oauth_name] = ''
    get '/oauth'
    assert_redirected_to signin_path
    assert_equal l(:oauth_invalid_provider), flash[:error]
  end

  def test_oauth_callback_csrf
    get '/oauth2callback'
    assert_response :unprocessable_content
  end
end
