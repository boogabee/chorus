class OldReleaseCleaner
  def initialize(logger)
    @logger = logger
  end

  def remove_except(new_version, previous_version)
    base_dir = File.dirname(new_version)
    raise StandardError unless base_dir == File.dirname(previous_version)

    Dir.foreach(base_dir) do |relative_path_to_version|
      next if %w(. ..).include?(relative_path_to_version)

      full_path_to_version = File.join(base_dir, relative_path_to_version)

      remove_version(full_path_to_version) unless [new_version, previous_version].include?(full_path_to_version)
    end
  end

  private

  def remove_version(version)
    return unless File.directory?(version)

    @logger.log "Removing outdated release: #{version}"
    %x(chmod -R 0777 #{version})
    FileUtils.rm_rf(version)
  end
end
