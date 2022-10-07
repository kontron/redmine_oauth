# encoding: utf-8
# frozen_string_literal: true
#
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

class RedmineOAuthControllerTest < Redmine::ControllerTest
  include Redmine::I18n
  tests RedmineOauthController

  def setup
    User.current = nil
  end

  def test_oauth
    with_settings plugin_redmine_oauth: { 'oauth_name' => '' } do
      get :oauth
      assert_redirected_to signin_path
      assert_equal l(:oauth_invalid_provider), flash[:error]
    end
  end

  def test_oauth_callback_csrf
    get :oauth_callback
    assert_response 422
  end

end
