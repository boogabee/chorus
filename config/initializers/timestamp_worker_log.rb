require 'clockwork'
require 'queue_classic'

module QC
  def self.log(data)
    Scrolls.log({ :timestamp => Time.current.to_s, :lib => :queue_classic, :level => :debug}.merge(data))
  end
end

module Clockwork
  def log(msg)
    config[:logger].info(Time.current.to_s + ": " + msg)
  end
end