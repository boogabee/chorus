require 'fileutils'

class ChorusLogger
  attr_writer :logfile

  def initialize(options={})
    @logfile = options[:logfile]
    @debug = options[:debug]
  end

  def debug(message)
    log(message) if @debug
  end

  def log(message)
    FileUtils.mkdir_p(File.dirname(filename))
    File.open(filename, 'a') { |f| f.puts(message) }
  end

  def capture_output(command)
    system "#{command} >> #{filename} 2>&1"
  end

  private
  def filename
    @fullpath ||= File.expand_path(@logfile)
  end
end
