require 'securerandom'
require 'pathname'
require 'fileutils'

namespace :development do
  desc "Generate config/secret.token which is used for signing cookies"
  task :generate_secret_token do
    secret_token_file = Pathname.new(__FILE__).dirname.join("../../config/secret.token")
    secret_token_file.open("w") { |f| f << SecureRandom.hex(64) } unless secret_token_file.exist?
  end

  desc "Generate config/secret.key which is used for encrypting saved database passwords"
  task :generate_secret_key do
    secret_key_file = Pathname.new(__FILE__).dirname.join("../../config/secret.key")
    next if secret_key_file.exist?

    passphrase = Random.new.bytes(32)
    secret_key = Base64.strict_encode64(OpenSSL::Digest.new("SHA-256", passphrase).digest)
    secret_key_file.open("w") { |f| f << secret_key }
  end

  desc "Copy database.yml.example to database.yml"
  task :generate_database_yml do
    root = Pathname.new(__FILE__).dirname.join("../..")
    database_yml_example = root.join("config/database.yml.example")
    database_yml = root.join("config/database.yml")
    FileUtils.cp(database_yml_example.to_s, database_yml.to_s) unless database_yml.exist?
  end

  desc "Initialize the database and create the database user used by Chorus"
  task :init_database => [:generate_database_yml] do
    root = Pathname.new(__FILE__).dirname.join("../..")
    postgres_port = `ruby #{File.join(root, 'packaging', 'get_postgres_port.rb')}`.chomp
    next if root.join("postgres-db").exist?

    `DYLD_LIBRARY_PATH=#{root}/postgres/lib LD_LIBRARY_PATH=#{root}/postgres/lib #{root}/postgres/bin/initdb -D #{root}/postgres-db -E utf8`
    `CHORUS_HOME=#{root} #{root}/packaging/chorus_control.sh start postgres`
    `DYLD_LIBRARY_PATH=#{root}/postgres/lib LD_LIBRARY_PATH=#{root}/postgres/lib #{root}/postgres/bin/createuser -hlocalhost -p #{postgres_port} -sdr postgres_chorus`

    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed_development"].invoke
    `CHORUS_HOME=#{root} #{root}/packaging/chorus_control.sh stop postgres`
  end

  desc "Initialize development environment.  Includes initializing the database and creating secret tokens"
  task :init => [:generate_secret_token, :generate_secret_key, :init_database]
end