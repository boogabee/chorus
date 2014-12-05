class RunWorkFlowTask < JobTask

  belongs_to :payload, :class_name => 'AlpineWorkfile'

  def perform
    result = RunWorkFlowTaskResult.create(:started_at => Time.current, :name => derived_name)

    run_workflow

    wait_until { finished? || killed? }
    raise StandardError.new('Canceled by User') if killed?

    result.finish :status => JobTaskResult::SUCCESS, :payload_id => payload.id, :payload_result_id => payload_result_id
  rescue StandardError => e
    result.finish :status => JobTaskResult::FAILURE, :message => e.message
  ensure
    idle!
  end

  def attach_payload(params)
    self.payload = AlpineWorkfile.find params[:workfile_id]
  end

  def update_attributes(params)
    attach_payload(params) if params[:workfile_id]
    super
  end

  def self.sleep_time
    45
  end

  def kill
    if killable_id
      Alpine::API.stop_work_flow(self)
      update_attribute(:killable_id, nil)
    end
  end

  private

  def build_task_name
    "Run #{payload.file_name}"
  end

  def run_workflow
    killable_id = Alpine::API.run_work_flow_task(self)
    update_attributes!(:status => JobTask::RUNNING, :killable_id => killable_id)
  end

  def finished?
    reload.status == JobTask::FINISHED
  end

  def killed?
    !(reload.killable_id)
  end

  def wait_until
    Timeout::timeout (60*60*12).seconds do
      until yield
        sleep self.class.sleep_time
      end
    end
  end
end
