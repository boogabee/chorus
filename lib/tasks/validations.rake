require_relative '../task_helpers/existing_data_sources_validator'

namespace :validations do
  desc 'Check Data Sources'
  task :data_source => :environment do
    legacy_gpdb_instance = Class.new(ActiveRecord::Base) do
      table_name = 'gpdb_instances'
    end

    data_valid = ExistingDataSourcesValidator.run([
      legacy_gpdb_instance,
      DataSource,
      HdfsDataSource,
      GnipDataSource
    ])

    exit(1) unless data_valid
  end
end
