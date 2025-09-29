# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine OAuth plugin.
#
# Redmine OAuth plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine OAuth plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine OAuth plugin. If not, see
# <https://www.gnu.org/licenses/>.

# Load the normal Rails helper
require File.expand_path('../../../../../test/test_helper', __FILE__)

# Account controller patch
class AccountControllerTest < ActionDispatch::IntegrationTest

  def test_login_oauth
    get '/login', headers: { 'HTTP_COOKIE' => 'oauth_autologin=1;' }
    assert_redirected_to oauth_path
  end

  def test_login
    get '/login'
    assert_response :success
  end

  def test_logout
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    Setting.plugin_redmine_oauth[:oauth_logout] = nil
    post '/logout'
    assert_redirected_to home_path
  end
end
