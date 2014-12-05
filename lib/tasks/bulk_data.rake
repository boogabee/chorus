require_relative '../task_helpers/bulk_data'

namespace :bulk_data do
  desc "Bulk load user data into Chorus"
  task :load_users, [:csv_file, :admin_username] => :environment do |t, args|
    BulkData.load_users_from_csv args[:csv_file], args[:admin_username]
  end

  unless Rails.env.production?
    task :generate_fake_users, [:csv_file, :user_count] do |t, args|
      BulkData.create_fake_users args[:csv_file], args[:user_count].to_i
    end
  end

  namespace :fake_data do
    task :create_workspaces, [:count] => :environment do |t, args|
      BulkData.create_workspaces args[:count].to_i
    end

    task :add_instance, [:admin_username, :data_source_name] => :environment do |t, args|
      BulkData.create_gpdb_data_source args[:admin_username], args[:data_source_name]
    end

    task :add_sandboxes, [:admin_username, :data_source_name] => :environment do |t, args|
      BulkData.add_sandboxes args[:admin_username], args[:data_source_name]
    end

    task :add_workfiles, [:admin_username, :workfiles_per_workspace] => :environment do |t, args|
      BulkData.add_workfiles args[:admin_username], args[:workfiles_per_workspace].to_i
    end

    task :load_all, [:admin_username, :workspace_count, :data_source_name, :workfiles_per_workspace] do |t, args|
      Rake::Task['bulk_data:fake_data:create_workspaces'].invoke(args[:workspace_count])
      Rake::Task['bulk_data:fake_data:add_instance'].invoke(args[:admin_username], args[:data_source_name])
      Rake::Task['bulk_data:fake_data:add_sandboxes'].invoke(args[:admin_username], args[:data_source_name])
      Rake::Task['bulk_data:fake_data:add_workfiles'].invoke(args[:admin_username], args[:workfiles_per_workspace])
    end
  end
end