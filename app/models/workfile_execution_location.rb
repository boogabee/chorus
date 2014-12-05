class WorkfileExecutionLocation < ActiveRecord::Base
  attr_accessible :workfile, :execution_location

  belongs_to :workfile, polymorphic: true
  belongs_to :execution_location, polymorphic: true

  validates_presence_of :execution_location
end