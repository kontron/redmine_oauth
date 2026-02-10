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
require File.expand_path('../../../../test/test_helper', __FILE__)

module RedmineOAuth
  module Test
    # Integration test
    class IntegrationTest < Redmine::IntegrationTest
      def initialize(name)
        super
        # Load all plugin's fixtures
        dir = File.join(File.dirname(__FILE__), 'fixtures')
        ext = '.yml'
        Dir.glob("#{dir}/**/*#{ext}").each do |file|
          fixture = File.basename(file, ext)
          ActiveRecord::FixtureSet.create_fixtures dir, fixture
        end
      end
    end
  end
end
