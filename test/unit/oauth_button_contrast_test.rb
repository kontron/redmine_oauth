# frozen_string_literal: true

# Redmine plugin OAuth
#
# liusumark <https://github.com/liusumark>
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

require File.expand_path('../integration_test', __dir__)

# Checks foreground contrast for administrator-configured OAuth button colors.
class OauthButtonContrastTest < ActiveSupport::TestCase
  def test_dark_background_has_light_text
    assert_equal '#FFFFFF', OauthProvider.new(button_color: '#102030').button_font_color
  end

  def test_light_background_has_dark_text
    assert_equal '#000000', OauthProvider.new(button_color: '#ffffff').button_font_color
  end

  def test_invalid_color_preserves_theme_foreground
    assert_equal 'currentColor', OauthProvider.new(button_color: nil).button_font_color
  end
end
