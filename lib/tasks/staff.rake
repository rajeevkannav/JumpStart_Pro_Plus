# Operator-only staff management. No form or param sets users.staff; these
# tasks are the only way to grant or revoke it.
#
#   bin/rails "staff:grant[person@example.com]"
#   bin/rails "staff:revoke[person@example.com]"
namespace :staff do
  desc "Make the user with the given email staff"
  task :grant, [ :email ] => :environment do |_task, args|
    User.set_staff!(args[:email], true)
    puts "#{args[:email].to_s.strip.downcase} is now staff."
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    abort e.message
  end

  desc "Remove staff from the user with the given email"
  task :revoke, [ :email ] => :environment do |_task, args|
    User.set_staff!(args[:email], false)
    puts "#{args[:email].to_s.strip.downcase} is no longer staff."
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    abort e.message
  end
end
