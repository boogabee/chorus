require Rails.root + "app/models/chorus_config"
require_relative "../task_helpers/backup_restore"

namespace :backup do

  desc 'create a backup'
  task :create, [:backup_dir, :rolling_days] do |t, args|
    rolling_days = args[:rolling_days].empty? ? nil : args[:rolling_days].to_i
    BackupRestore.backup args[:backup_dir], rolling_days
  end

  desc 'restore from a backup'
  task :restore, [:backup_file, :silent] do |t, args|
    silent = args[:silent].empty? ? nil : args[:silent]
    BackupRestore.restore args[:backup_file], silent
  end
end
