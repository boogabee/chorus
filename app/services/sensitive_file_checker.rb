module SensitiveFileChecker
  def self.files
    %W{
      #{path_prefix}/config/secret.token
      #{path_prefix}/config/secret.key
      #{path_prefix}/config/chorus.properties
    }
  end

  def self.path_prefix
    if Object.const_defined? :Rails
      Rails.root
    else
      ENV['CHORUS_HOME']
    end
  end

  def self.mode(file)
    File.stat(file).mode & 0777
  end

  def self.check
    unprotected_files.empty?
  end

  def self.unprotected_files
    files.select { |file| mode(file) != 0600 }
  end

  def self.errors
    unprotected_files.collect {|file| "FATAL ERROR: #{file} is readable or writable by other users."}
  end

end