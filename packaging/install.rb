#!./chorus_installation/bin/ruby

require_relative 'chorus_installation/packaging/install/version_detector'
require_relative 'chorus_installation/packaging/install/chorus_logger'
require_relative 'chorus_installation/packaging/install/installer_io'
require_relative 'chorus_installation/packaging/install/chorus_executor'
require_relative 'chorus_installation/packaging/install/chorus_installer'

if __FILE__ == $0
  begin
    silent = !!ARGV.delete('-a')
    keep = !!ARGV.delete('--keep')
    logger = ChorusLogger.new({:debug => true})
    installer = ChorusInstaller.new({
        installer_home: File.dirname(__FILE__),
        version_detector: VersionDetector.new,
        logger: logger,
        old_release_cleaner: OldReleaseCleaner.new(logger),
        io: InstallerIO.new(silent),
        executor: ChorusExecutor.new({:logger => logger, :debug => true})
    })

    installer.install
    puts 'Installation completed.'
    if installer.upgrade_existing?
      puts ''
      puts 'Confirm custom configuration settings as directed in the upgrade guide before restarting Chorus.'
    end
    puts 'To start Chorus, run the following commands:'
    puts "source #{installer.destination_path}/chorus_path.sh"
    puts 'chorus_control.sh start'
  rescue InstallerErrors::InstallationFailed => e
    puts 'An error has occurred. Trying to back out and restore previous state...'
    installer.remove_and_restart_previous! unless keep
    puts 'Please check the installation log (install.log) for failure details.'
    exit 1
  rescue => e
    File.open('install.log', 'a') { |f| f.puts "#{e.class}: #{e.message}" }
    puts 'Failed to start chorus back up'
    exit 1
  ensure
    if STDIN.tty?
      exec 'stty echo'
    end
  end
end
