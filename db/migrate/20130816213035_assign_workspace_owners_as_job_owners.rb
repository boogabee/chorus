class AssignWorkspaceOwnersAsJobOwners < ActiveRecord::Migration
  class Job < ActiveRecord::Base
    belongs_to :workspace
    belongs_to :owner, :class_name => 'User'
  end

  class Workspace < ActiveRecord::Base
    belongs_to :owner, :class_name => 'User'
  end

  def up
    Job.find_each do |job|
      job.owner = job.workspace.owner
      job.save!
    end
  end

  def down
  end
end
