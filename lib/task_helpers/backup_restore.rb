require_relative 'safe_mktmpdir'
require 'pathname'
require 'open3'
require 'tempfile'
require 'yaml'

module BackupRestore
  BACKUP_FILE_PREFIX = 'chorus_backup_'
  DATABASE_DATA_FILENAME = 'database.gz'
  ASSET_FILENAME = 'assets_storage_path'
  ALPINE_BACKUP = 'alpine_data_repository'
  MODELS_WITH_ASSETS = %w{csv_files attachments note_attachments users workfile_versions workspaces}

  def self.backup(backup_dir, rolling_days = nil)
    Backup.new(backup_dir, rolling_days).backup
  end

  def self.restore(backup_filename, do_not_warn=false)
    Restore.new(backup_filename, do_not_warn).restore
  end

  module SharedMethods
    def log(*args)
      puts *args
    end

    def db_config
      Rails.application.config.database_configuration[Rails.env]
    end

    def database_name
      db_config['database']
    end

    def database_port
      db_config['port']
    end

    def asset_path
      Rails.root.join "system"
    end

    def chorus_config
      @chorus_config ||= ChorusConfig.new
    end

    def chorus_config=(value)
      @chorus_config = value
    end

    def asset_path_wildcard
      "{" + (MODELS_WITH_ASSETS.join ",") + "}"
    end

    def capture_output(command, options = {})
      `#{command} 2>&1`.tap do |output|
        unless $?.success?
          failure_message = options[:error] || "Command '#{command}' failed."
          $stderr.puts [failure_message, output]
          raise failure_message
        end
      end
    end

    def postgres_username
      @pg_user ||= YAML.load_file(Rails.root.join('config/database.yml'))['production']['username']
    end

    def adr_container
      File.dirname(ENV['ALPINE_DATA_REPOSITORY'])
    end
  end

  class Backup
    include BackupRestore::SharedMethods
    attr_accessor :backup_dir, :rolling_days, :temp_dir

    def initialize(backup_dir, rolling_days = nil)
      rolling_days.nil? || rolling_days > 0 || raise("Must specify a positive integer for the number of rolling days (value was #{rolling_days}).")

      self.backup_dir = File.expand_path(backup_dir)
      FileUtils.mkdir_p backup_dir
      self.rolling_days = rolling_days
    end

    def backup
      SafeMktmpdir.mktmpdir(BACKUP_FILE_PREFIX) do |temp_dir|
        self.temp_dir = Pathname.new(temp_dir)
        Dir.chdir(temp_dir) do
          dump_database
          compress_assets
          backup_alpine if ENV['ALPINE_DATA_REPOSITORY'].present?
          package_backup
        end
      end
      delete_old_backups
    end

    def dump_database
      log "Dumping database contents..."

      pg_dump = "#{ENV['CHORUS_HOME']}/packaging/pg_dump.sh -Fc"
      pg_dump += " --compress=0" # because our postgres 9.2 install warns that it can't compress otherwise
      pg_dump += " -p #{database_port} -U #{postgres_username} #{database_name}"
      capture_output "#{pg_dump} | gzip > #{DATABASE_DATA_FILENAME}", :error => "Database dump failed."
    end

    def compress_assets
      return unless Dir.exists?(asset_path)

      log "Compressing assets..."
      Dir.chdir asset_path do
        asset_list = Dir.glob asset_path_wildcard
        return if asset_list.empty?

        asset_string = asset_list.join " "
        asset_file = temp_dir.join(ASSET_FILENAME + ".tgz")
        capture_output "tar czf #{asset_file} #{asset_string}",
                       :error => "Compressing assets failed."
      end
    end

    def backup_alpine
      log 'Backing up Alpine...'
      Dir.chdir adr_container do
        capture_output "tar czf #{temp_dir.join(ALPINE_BACKUP + ".gz")} ALPINE_DATA_REPOSITORY", :error => 'Compressing alpine data directory failed.'
      end
    end

    def delete_old_backups
      return unless rolling_days
      log "Removing backups more than #{rolling_days} #{"day".pluralize(rolling_days)} old..."

      oldest_allowed_timestamp = rolling_days.days.ago.strftime('%Y%m%d_%H%M%S')

      timestamp_matcher = oldest_allowed_timestamp.gsub(/\d/, "?")

      Dir.glob(backup_dir + "/#{BACKUP_FILE_PREFIX}#{timestamp_matcher}.tar") do |filename|
        timestamp = filename.gsub(backup_dir + "/" + BACKUP_FILE_PREFIX, "")

        if timestamp < oldest_allowed_timestamp
          log "Deleting '#{filename}'"
          File.delete(filename)
        end
      end
    end

    def package_backup
      %w{version_build config/chorus.properties config/secret.token config/secret.key}.map { |f| Rails.root.join f }.each do |file|
        FileUtils.cp file, "." if File.exists?(file)
      end

      timestamp = Time.current.strftime '%Y%m%d_%H%M%S'
      backup_filename = File.join(backup_dir, "#{BACKUP_FILE_PREFIX}#{timestamp}.tar")

      capture_output "tar cf #{backup_filename} *", :error => "Packaging failed."
      log "Created backup archive file: #{backup_filename}"
    end
  end

  class Restore
    include BackupRestore::SharedMethods
    attr_accessor :backup_filename, :temp_dir, :do_not_warn_before_restore

    def initialize(backup_filename, do_not_warn)
      self.backup_filename = backup_filename
      self.do_not_warn_before_restore = do_not_warn
    end

    def restore
      prompt_user unless do_not_warn_before_restore

      without_connection do
        full_backup_filename = File.expand_path(backup_filename)
        SafeMktmpdir.mktmpdir "chorus_restore" do |tmp_dir|
          self.temp_dir = Pathname.new tmp_dir
          Dir.chdir tmp_dir do
            capture_options = {:error => "Could not unpack backup file '#{backup_filename}'"}
            capture_output "tar xf #{full_backup_filename}", capture_options
            backup_version = capture_output("cat version_build", capture_options).strip
            current_version = capture_output("cat #{Rails.root.join 'version_build'}", capture_options).strip

            compare_versions(backup_version, current_version)

            FileUtils.cp "chorus.properties", Rails.root.join("config/chorus.properties") if File.exists?("chorus.properties")
            FileUtils.cp "secret.key", Rails.root.join("config/secret.key") if File.exists?("secret.key")
            FileUtils.cp "secret.token", Rails.root.join("config/secret.token") if File.exists?("secret.token")
            self.chorus_config = ChorusConfig.new

            restore_assets
            restore_database
            restore_alpine
          end
        end
        true
      end
    end

    PROMPT = <<PROMPT
Continuing will overwrite existing assets and data. It is strongly advised that
you have a recent backup available before performing a restore.

Are you sure you want to continue? (Y/N):
PROMPT

    def prompt_user
      unless do_not_warn_before_restore

        loop do
          print PROMPT
          input = get_input
          print "#{input}\n"

          input.downcase!

          break if 'y' == input
          exit(false) if 'n' == input
        end
      end
    end

    def get_input
      STDIN.getc
    end

    def restore_assets
      log "Deleting existing assets..."
      asset_pathname = Pathname.new asset_path
      Dir.exists? asset_pathname and Dir.chdir asset_pathname do
        MODELS_WITH_ASSETS.each do |model|
          FileUtils.rm_r asset_pathname.join(model) rescue Errno::ENOENT
        end
      end

      log "Restoring backed up assets..."
      asset_file = temp_dir.join(ASSET_FILENAME + ".tgz")
      if File.exists? asset_file
        FileUtils.mkdir_p asset_pathname and Dir.chdir asset_pathname do
          capture_output "tar xf #{asset_file}",
                         :error => "Restoring assets failed."
        end
      end
    end

    def restore_database
      log "Restoring database..."
      capture_output "DYLD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib LD_LIBRARY_PATH=$CHORUS_HOME/postgres/lib exec $CHORUS_HOME/postgres/bin/dropdb -p #{database_port} -U #{postgres_username} #{database_name}", :error => "Existing database could not be dropped."
      capture_output "gunzip -c #{DATABASE_DATA_FILENAME} | #{ENV['CHORUS_HOME']}/postgres/bin/pg_restore -C -p #{database_port} -U #{postgres_username} -d postgres", :error => "Could not restore database."
    end

    def restore_alpine
      alpine_file = temp_dir.join(ALPINE_BACKUP + '.gz')
      if Dir.exists? ENV['ALPINE_DATA_REPOSITORY']
        log 'Deleting existing Alpine data...'
        FileUtils.rm_r Pathname.new(ENV['ALPINE_DATA_REPOSITORY']) rescue Errno::ENOENT
      end
      if File.exists? alpine_file
        log 'Restoring Alpine data...'
        Dir.chdir adr_container do
          capture_output "tar xf #{alpine_file}", :error => 'Restoring Alpine data failed.'
        end
      end
    end

    def compare_versions(backup_version, current_version)
      if backup_version != current_version
        raise "Backup version ('#{backup_version}') differs from installed chorus version ('#{current_version}')"
      end
    end

    def without_connection
      existing_connection = ActiveRecord::Base.connection_handler.active_connections?
      if existing_connection
        connection_config = ActiveRecord::Base.connection_config
        ActiveRecord::Base.connection.disconnect!
      end
      yield
    ensure
      ActiveRecord::Base.establish_connection connection_config if existing_connection
    end
  end
end
