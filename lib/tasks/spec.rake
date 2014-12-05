unless Rails.env.production?
  task :default => [:spec]

  task :data_source_host_check_stale do
    `echo "#{ENV['GPDB_HOST']}" > tmp/GPDB_HOST_STALE`
    `echo "#{ENV['ORACLE_HOST']}" > tmp/ORACLE_HOST_STALE`
    `echo "#{ENV['HADOOP_HOST']}" > tmp/HADOOP_HOST_STALE`
    `echo "#{ENV['JDBC_HOST']}" > tmp/JDBC_HOST_STALE`
    `echo "#{ENV['PG_HOST']}" > tmp/PG_HOST_STALE`
  end

  # remove default rspec_rails tasks and prereqs to start clean (because it assumes the database is test)
  Rake::Task["spec"].clear
  spec_prereq = if Rails.env.test?
    "db:test:clone_structure"
  else
    :noop
  end
  task :noop

  desc 'Run backend specs'
  RSpec::Core::RakeTask.new(:spec => spec_prereq) do |t|
    t.pattern = 'spec/{concerns,controllers,initializers,install,lib,mailers,mixins,models,permissions,presenters,requests,scripts,services,validators}/**/*_spec.rb'
  end
  task :spec => [:data_source_host_check_stale]

  desc 'Run all backend specs including api doc specs'
  task :all => [:spec, :api_docs]

  desc 'Run Capybara integration specs'
  RSpec::Core::RakeTask.new('spec:chorus_integration') do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
  task :spec => [:data_source_host_check_stale]
end
