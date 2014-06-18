namespace :demo do
  desc "Remove users and sessions more than one hour old"
  task :clean => :environment do
    User.destroy_all(["is_admin = ? AND created_at < ?", false, 1.hours.ago])
    ActiveRecord::SessionStore::Session.delete_all(["updated_at < ?", 1.hours.ago])
  end
end
