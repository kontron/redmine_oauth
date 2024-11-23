# frozen_string_literal: true

# Redmine plugin OAuth
#
# Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Load the normal Rails helper
require File.expand_path('../../../../../test/test_helper', __FILE__)

# Account controller patch
class AccountControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :email_addresses

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
