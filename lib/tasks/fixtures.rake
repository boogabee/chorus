unless Rails.env.production?
  namespace :jasmine do
    desc 'Regenerate JSON fixtures for jasmine tests'
    RSpec::Core::RakeTask.new(:fixtures) do |t|
      system("rm -rf spec/javascripts/fixtures/backbone/*")
      options = ["--tag fixture"]
      options << "--tag ~greenplum_integration" unless ENV['GPDB_HOST']
      t.rspec_opts = options
      t.pattern = 'spec/controllers/**/*_spec.rb'
    end
  end
end