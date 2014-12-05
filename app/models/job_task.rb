class JobTask < ActiveRecord::Base
  include SoftDelete
  attr_accessible :index, :type, :job, :status, :payload_result_id, :killable_id

  RUNNING = 'running'
  FINISHED = 'finished'
  CANCELED = 'canceled'

  belongs_to :job
  validates_presence_of :job_id
  delegate :workspace, :to => :job

  before_create :provide_index
  validates :type, :presence => true
  after_destroy :compact_indices

  JobTaskFailure = Class.new(StandardError)

  def self.assemble!(params, job)
    klass = "#{params[:action]}_task".classify.constantize rescue NameError
    raise ApiValidationError.new(:entity_type, :invalid) unless klass < JobTask
    task = klass.new(params)
    task.job = job
    task.attach_payload params
    task.save!
    task
  end

  def action
    type.gsub(/Task\z/, '').underscore
  end

  def perform
    raise NotImplementedError
  end

  def valid_payload?
    payload.present?
  end

  def derived_name
    (valid_payload? && build_task_name) || '[invalid task]'
  end

  private

  def build_task_name
    raise NotImplementedError
  end

  def provide_index
    self.index = job.next_task_index
  end

  def compact_indices
    job.compact_indices
  end

  def idle!
    update_attributes!(:status => nil)
  end
end
