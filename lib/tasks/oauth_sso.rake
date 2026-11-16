# frozen_string_literal: true

namespace :redmine_oauth do
  desc 'Convert an explicit list of users to SSO (LOGINS=a,b; APPLY=1 to commit)'
  task migrate_sso: :environment do
    logins = ENV.fetch('LOGINS', '').split(',').map(&:strip).reject(&:empty?).uniq
    abort 'Provide LOGINS=user1,user2 (no automatic discovery of OAuth users is possible)' if logins.empty?
    users = logins.map { |login| User.find_by!(login: login) }
    if users.any?(&:admin?) && ENV['INCLUDE_ADMINS'] != '1'
      abort 'Administrator selected. Keep a separate local administrator; use INCLUDE_ADMINS=1 to override.'
    end
    users.each { |user| puts "#{user.login}: #{user.auth_source&.name || 'Internal'} -> OAuth SSO" }
    if ENV['APPLY'] == '1'
      User.transaction do
        users.each { |user| AuthSourceOauth.bind!(user) }
      end
      puts 'Converted. Local passwords and recovery/autologin/session tokens removed.'
    else
      puts 'Dry run. Repeat with APPLY=1 to commit.'
    end
  end
end
