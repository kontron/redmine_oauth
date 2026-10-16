# frozen_string_literal: true

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
