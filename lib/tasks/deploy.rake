require_relative '../task_helpers/deployer'

desc "Deploy an installer package file to a server"
task :deploy, [:server, :package_file] do |t, args|
  server = args[:server]
  package_file = args[:package_file]
  unless package_file && server
    puts "You have to specify package_file to deploy and server to deploy to"
    exit 1
  end
  deploy_configuration = YAML.load_file(Rails.root.join('config', 'deploy.yml'))[server]
  Deployer.new(deploy_configuration).deploy(package_file)
end

desc "Setup a server with load test data"
task :setup_load_test, [:server, :user_csv_file] do |t, args|
  server = args[:server]
  user_csv_file = args[:user_csv_file]
  unless server && user_csv_file
    puts "You have to specify server and csv file of users"
    exit 1
  end

  deploy_configuration = YAML.load_file(Rails.root.join('config', 'deploy.yml'))[server]
  Deployer.new(deploy_configuration).setup_load_test(user_csv_file)
end