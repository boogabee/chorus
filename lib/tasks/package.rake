require_relative '../../version'
require_relative '../task_helpers/package_maker'

namespace :package do
  task :check_clean_working_tree do
    unless ENV['IGNORE_DIRTY'] || system('git diff-files --quiet')
      puts "You have a dirty working tree. You must stash or commit your changes before packaging. Or run with IGNORE_DIRTY=true"
      exit(1)
    end
  end

  task :prepare_app => :check_clean_working_tree do
    Rake::Task[:'api_docs:package'].invoke
    system("rake assets:precompile RAILS_ENV=production RAILS_GROUPS=assets --trace") || exit(1)
    system("bundle exec jetpack .") || exit(1)
    PackageMaker.write_version
  end

  desc 'Generate binary installer'
  task :installer => :prepare_app do
    PackageMaker.make_installer
  end

  task :prepare_hdfs_jar do
    system 'git submodule update --init'
    system 'cd chorushdfs; ./install_jars.sh; mvn -Dmaven.test.skip=true clean package'
    FileUtils.rm Dir.glob('vendor/hadoop/hdfs-query-service-*.jar'), :force => true
    FileUtils.mv Dir.glob('chorushdfs/hdfs-query-service/target/hdfs-query-service-*.jar'), 'vendor/hadoop', :force => true
  end
end
