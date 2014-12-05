class JobResult < ActiveRecord::Base
  attr_accessible :started_at, :job_id, :finished_at, :succeeded

  validates_presence_of :started_at, :finished_at
  validates_inclusion_of :succeeded, :in => [true, false]
  belongs_to :job
  has_many :job_task_results
end
