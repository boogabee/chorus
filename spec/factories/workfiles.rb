require 'factory_girl'

FactoryGirl.define do
  factory :alpine_workfile, aliases: [:work_flow] do
    owner
    workspace
    description "Using two datasources to #{Faker::Company.bs.downcase}."
    file_name Faker::Lorem.word

    factory :work_flow_with_all_data_sources do
      after(:create) do |workfile, evaluator|
        gpdb = FactoryGirl.create(:gpdb_data_source, owner: workfile.owner)
        oracle = FactoryGirl.create(:oracle_data_source, owner: workfile.owner)
        database = FactoryGirl.create(:gpdb_database, data_source: gpdb)
        hadoop = FactoryGirl.create(:hdfs_data_source, owner: workfile.owner)
        workfile.workfile_execution_locations.create(execution_location: database)
        workfile.workfile_execution_locations.create(execution_location: hadoop)
        workfile.workfile_execution_locations.create(execution_location: oracle)
      end
    end
  end

  factory :workfile do
    owner
    workspace
    description 'A nice description'
    file_name 'workfile.doc'
  end

  factory :chorus_workfile do
    owner
    workspace
    additional_data ''
    description 'A nice description'
    file_name 'chorus_workfile.doc'
  end

  factory :workfile_version do
    association :workfile, :factory => :chorus_workfile
    version_num '1'
    owner
    commit_message 'Factory commit message'
    modifier
  end

  factory :workfile_draft do
    association :workfile, :factory => :chorus_workfile
    owner
    content 'Excellent content'
  end
end
