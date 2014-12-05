class SystemStatus < ActiveRecord::Base
  validates_length_of :message, :maximum => 2048
end
