require_relative '../../version'

namespace :package do
  task :check_clean_working_tree do
    unless ENV['IGNORE_DIRTY'] || system('git diff-files --quiet')
      puts "You have a dirty working tree. You must stash or commit your changes before packaging. Or run with IGNORE_DIRTY=true"
      exit(1)
    end
  end

  task :prepare_app => :check_clean_working_tree do
    #Rake::Task[:'api_docs:package'].invoke
    #system "rake assets:precompile RAILS_ENV=production RAILS_GROUPS=assets --trace"
    system "bundle exec jetpack ."
    PackageMaker.write_version
  end

  desc 'Generate binary installer'
  task :installer => :prepare_app do
    PackageMaker.make_installer
  end

  task :stage => :installer do
    deploy_configuration = YAML.load_file(Rails.root.join('config', 'deploy.yml'))['stage']
    PackageMaker.deploy(deploy_configuration)
  end

  task :cleanup do
    PackageMaker.clean_workspace
  end
end

packaging_tasks = Rake.application.top_level_tasks.select { |task| task.to_s.match(/^package:/) }

last_packaging_task = packaging_tasks.last
Rake::Task[last_packaging_task].enhance do
  Rake::Task[:'package:cleanup'].invoke
end if last_packaging_task

desc "Deploy an installer package file to a server"
task :deploy, [:server, :package_file] do |t, args|
  server = args[:server]
  package_file = args[:package_file]
  unless package_file && server
    puts "You have to specify package_file to deploy and server to deploy to"
    exit 1
  end
  deploy_configuration = YAML.load_file(Rails.root.join('config', 'deploy.yml'))[server]
  PackageMaker.deploy(deploy_configuration, package_file)
end


module PackageMaker
  PATHS_TO_PACKAGE = [
      "bin/",
      "app/",
      "config/",
      "db/",
      "doc/",
      "lib/",
      "packaging/",
      "public/",
      "script/",
      "vendor/",
      "WEB-INF/",
      "Gemfile",
      "Gemfile.lock",
      "README.md",
      "Rakefile",
      "config.ru",
      "version.rb",
      "version_build",
      ".bundle/",
  ]

  extend self

  def make_installer
    rails_root = File.expand_path(File.dirname(__FILE__) + '/../../')
    install_root = rails_root + '/tmp/installer/'
    installer_path = install_root + 'chorus_installation'

    FileUtils.rm_rf(install_root)
    FileUtils.mkdir_p(installer_path)

    PATHS_TO_PACKAGE.each do |path|
      FileUtils.ln_s File.join(rails_root, path), File.join(installer_path, path)
    end

    FileUtils.ln_s File.join(rails_root, 'packaging/install.rb'), install_root

    system("#{rails_root}/packaging/makeself/makeself.sh --nocomp --follow --nox11 --nowait #{install_root} greenplum-chorus-#{version_name}.sh 'Chorus #{Chorus::VERSION::STRING} installer' ./chorus_installation/bin/ruby ../install.rb") || exit(1)
  end

  def upload(filename, config)
    host = config['host']
    path = config['install_path']
    postgres_build = config['postgres_build']
    legacy_path = config['legacy_path']

    File.open('install_answers.txt', 'w') do |f|
      # where the existing install lives
      if legacy_path.present?
        f.puts(legacy_path)
      else
        f.puts(path)
      end

      # confirm the upgrade
      f.puts('y')

      # where to install 2.2
      if legacy_path.present?
        f.puts(path)
      end
      f.puts(postgres_build)
    end

    # start old postgres
    run "ssh #{host} 'killall -9 -w postgres || true'"
    run "ssh #{host} 'killall -9 -w java || true'"
    run "ssh #{host} 'rm -rf ~/chorusrails'"
    edc_start = "JAVA_HOME=/usr/lib/jvm/jre-1.6.0-openjdk.x86_64 bin/edcsvrctl start"
    # run edc_start twice because it fails the first time
    run "ssh #{host} 'cd ~/chorus;. edc_path.sh; #{edc_start} && #{edc_start}'"

    # run upgrade scripts
    run "scp #{filename} #{host}:~"
    run "ssh #{host} rm ~/install_answers.txt"
    run "scp install_answers.txt #{host}:~"
    run "ssh #{host} 'cat /dev/null > #{path}/install.log'"
    install_success = run "ssh #{host} 'cd ~ && ./#{filename} ~/install_answers.txt'"
    run "scp #{host}:#{path}/install.log install.log"

    run "ssh #{host} 'cd ~; rm #{filename}'"
    if install_success
      builds_to_keep = 5
      run "ssh #{host} 'test `ls #{path}/releases | wc -l` -gt #{builds_to_keep} && find #{path}/releases -maxdepth 1 -not -newer \"`ls -t | head -#{builds_to_keep + 1} | tail -1`\" -not -name \".\" -exec rm -rf {} \\;'"
    end

    raise StandardError.new("Installation failed!") unless install_success
  end

  def deploy(config, filename=nil)
    filename ||= "greenplum-chorus-#{version_name}.sh"
    upload(filename, config)
  end

  def clean_workspace
    run "rm -r .bundle"
  end

  def head_sha
    `git rev-parse HEAD`.strip[0..8]
  end

  def write_version
    File.open('version_build', 'w') do |f|
      f.puts version_name
    end
  end

  def run(cmd)
    puts cmd
    system cmd
  end

  def relative(path)
    current = Pathname.new(Dir.pwd)
    Pathname.new(path).relative_path_from(current).to_s
  end

  def version_name
    "#{Chorus::VERSION::STRING}-#{head_sha}"
  end
end

